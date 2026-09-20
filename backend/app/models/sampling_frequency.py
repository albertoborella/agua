import uuid
from datetime import datetime, timezone

from sqlmodel import Field, SQLModel


class SamplingFrequency(SQLModel, table=True):
    __tablename__ = "sampling_frequencies"

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    fuente_id: str = Field(foreign_key="water_sources.id", index=True)
    tipo_analisis_id: str = Field(foreign_key="analysis_types.id", index=True)
    frecuencia: str  # DIARIA, SEMANAL, QUINCENAL, MENSUAL
    dias_semana: str | None = None  # JSON string
    hora_esperada: str | None = None  # HH:MM
    activa: bool = Field(default=True)
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
