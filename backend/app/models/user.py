import uuid
from datetime import datetime, timezone

from sqlmodel import Field, SQLModel

from app.models.role import UserRole


class User(SQLModel, table=True):
    __tablename__ = "users"

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    tenant_id: str = Field(foreign_key="tenants.id", index=True)
    username: str
    email: str
    password_hash: str
    rol: str = Field(sa_column_kwargs={"comment": "ADMIN, OPERARIO, LABORATORISTA"})
    activo: bool = Field(default=True)
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )

    @property
    def role(self) -> UserRole:
        return UserRole(self.rol)

    @role.setter
    def role(self, value: UserRole) -> None:
        self.rol = value.value
