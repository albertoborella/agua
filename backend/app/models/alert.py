import uuid
from datetime import datetime, timezone

from sqlmodel import Field, SQLModel


class Alert(SQLModel, table=True):
    __tablename__ = "alerts"

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    tenant_id: str = Field(foreign_key="tenants.id", index=True)
    usuario_id: str = Field(foreign_key="users.id", index=True)
    tipo: str  # PENDIENTE, VENCIDA, PROGRAMADA
    fuente_id: str = Field(foreign_key="water_sources.id", index=True)
    tipo_analisis_id: str = Field(foreign_key="analysis_types.id", index=True)
    fecha_esperada: str  # YYYY-MM-DD
    leida: bool = Field(default=False)
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
