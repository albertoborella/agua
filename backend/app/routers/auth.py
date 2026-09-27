from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlmodel import Session

from app.database import get_tenant_engine
from app.middleware.auth import get_current_user
from app.schemas.auth import ChangePasswordRequest, RefreshRequest, TokenResponse
from app.services.auth_service import (
    authenticate_user,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    tenant_has_users,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    username = form_data.username
    password = form_data.password
    tenant_id = form_data.client_id or ""

    if not tenant_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Se requiere tenant_id (client_id)",
        )

    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        user = authenticate_user(session, username, password, tenant_id)
        if not user:
            # The tenant directory and its schema are created on first use, so
            # by this point the tables exist — an unknown company id just has
            # no users. A bare "Credenciales inválidas" for a company id the
            # user typed themselves (and mistyped) points at the password,
            # which is the wrong thing to go debug. Say which half is wrong.
            #
            # Enumeration tradeoff, recorded on purpose: this confirms whether
            # a company id is provisioned. The id is chosen by the user like a
            # username, there is no signup flow in this MVP, and the tenant list
            # is not a secret worth an hour of debugging — so a clear message
            # wins. If multi-tenancy ever grows a real provisioning/signup
            # flow, revisit this: at that point tenant ids become guessable
            # identifiers with real value, and this should collapse back into a
            # uniform 401.
            #
            # Raising HTTPException rather than letting the error escape is
            # also what makes this response readable from the browser. An
            # unhandled exception bubbles to Starlette's ServerErrorMiddleware,
            # which sits OUTSIDE CORSMiddleware, so the 500 it produces carries
            # no Access-Control-Allow-Origin and the console reports a CORS
            # failure instead of the real error. An HTTPException is handled
            # inside the router, so the response travels back out through
            # CORSMiddleware and the browser can actually read `detail`.
            if not tenant_has_users(session, tenant_id):
                raise HTTPException(
                    # 404, not 401: a 401 means "your credentials are wrong",
                    # which is not what happened, and it is the status the
                    # client's session-renewal path watches for.
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=(
                        "El ID de empresa no está registrado o no tiene "
                        "usuarios configurados. Verificá el ID e intentá de nuevo."
                    ),
                )
            # The tenant exists and simply got the wrong password. This branch
            # is the documented behaviour: do not fold it into the 404 above.
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciales inválidas",
                headers={"WWW-Authenticate": "Bearer"},
            )

        token_data = {"sub": user.id, "tenant": tenant_id, "rol": user.rol}
        access_token = create_access_token(token_data)
        refresh_token = create_refresh_token(token_data)

        return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=TokenResponse)
def refresh_token(request: RefreshRequest):
    payload = decode_token(request.refresh_token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token inválido o expirado",
        )

    token_data = {
        "sub": payload["sub"],
        "tenant": payload["tenant"],
        "rol": payload["rol"],
    }
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/change-password")
def change_password(
    request: ChangePasswordRequest,
    current_user: dict = Depends(get_current_user),
):
    tenant_id = current_user["tenant"]
    user_id = current_user["sub"]

    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        from app.models.user import User

        user = session.get(User, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        if not verify_password(request.current_password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Contraseña actual incorrecta",
            )

        user.password_hash = hash_password(request.new_password)
        session.add(user)
        session.commit()

    return {"message": "Contraseña actualizada correctamente"}
