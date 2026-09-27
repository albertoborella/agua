from datetime import datetime, timedelta, timezone

import bcrypt
from jose import JWTError, jwt
from sqlmodel import Session, select

from app.config import settings
from app.models.user import User


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.JWT_ACCESS_EXPIRE_MINUTES
    )
    to_encode.update({"exp": expire, "iat": datetime.now(timezone.utc)})
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(
        days=settings.JWT_REFRESH_EXPIRE_DAYS
    )
    to_encode.update({"exp": expire, "iat": datetime.now(timezone.utc)})
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def decode_token(token: str) -> dict | None:
    try:
        return jwt.decode(
            token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM]
        )
    except JWTError:
        return None


def authenticate_user(session: Session, username: str, password: str, tenant_id: str) -> User | None:
    user = session.exec(
        select(User).where(
            User.username == username,
            User.tenant_id == tenant_id,
            User.activo == True,
        )
    ).first()
    if not user or not verify_password(password, user.password_hash):
        return None
    return user


def tenant_has_users(session: Session, tenant_id: str) -> bool:
    """Whether this tenant has at least one user row, active or not.

    Used by the login route to tell "this company id is not provisioned"
    apart from "wrong password", which otherwise both collapse into a bare
    401 and send the user hunting for a password problem they do not have.

    Deliberately does NOT filter on `activo`: a tenant whose only users are
    deactivated still exists, and it must keep answering with the generic
    401 rather than claiming it was never configured.
    """
    return (
        session.exec(select(User.id).where(User.tenant_id == tenant_id).limit(1)).first()
        is not None
    )
