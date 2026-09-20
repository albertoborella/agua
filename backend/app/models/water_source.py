import uuid
from datetime import datetime, timezone

from sqlmodel import Field, SQLModel


class WaterSource(SQLModel, table=True):
    __tablename__ = "water_sources"

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    planta_id: str = Field(foreign_key="plants.id", index=True)
    tipo: str  # GRIFO or POZO
    nombre: str
    ubicacion: str | None = None
    activa: bool = Field(default=True)
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
