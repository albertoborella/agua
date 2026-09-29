from pydantic import BaseModel, field_validator

from app.models.role import UserRole


class UserCreate(BaseModel):
    username: str
    email: str
    password: str
    rol: str

    @field_validator("rol")
    @classmethod
    def validate_rol(cls, v: str) -> str:
        if not UserRole.is_valid(v):
            raise ValueError(f"Rol inválido. Valores permitidos: {', '.join(UserRole.values())}")
        return v


class UserUpdate(BaseModel):
    email: str | None = None
    rol: str | None = None
    activo: bool | None = None

    @field_validator("rol")
    @classmethod
    def validate_rol(cls, v: str | None) -> str | None:
        if v is not None and not UserRole.is_valid(v):
            raise ValueError(f"Rol inválido. Valores permitidos: {', '.join(UserRole.values())}")
        return v


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
