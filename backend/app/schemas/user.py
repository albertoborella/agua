from pydantic import BaseModel


class UserCreate(BaseModel):
    username: str
    email: str
    password: str
    rol: str  # ADMIN, OPERARIO, LABORATORISTA


class UserUpdate(BaseModel):
    email: str | None = None
    rol: str | None = None
    activo: bool | None = None


class UserResponse(BaseModel):
    id: str
    tenant_id: str
    username: str
    email: str
    rol: str
    activo: bool
    created_at: str


class ResetPasswordRequest(BaseModel):
    new_password: str
