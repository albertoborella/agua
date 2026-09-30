import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


class SampleRecord(SQLModel, table=True):
    __tablename__ = "sample_records"

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    tenant_id: str = Field(foreign_key="tenants.id", index=True)
    fuente_id: str = Field(foreign_key="water_sources.id", index=True)
    tipo_analisis_id: str = Field(foreign_key="analysis_types.id", index=True)
    operario_id: str = Field(foreign_key="users.id", index=True)
    frecuencia_id: Optional[str] = Field(default=None, foreign_key="sampling_frequencies.id", index=True)
    fecha: str  # YYYY-MM-DD
    hora: str  # HH:MM:SS
    sincronizada: bool = Field(default=False)
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    # Lab analysis fields
    estado_analisis: str = Field(default="PENDIENTE", index=True)  # PENDIENTE, ANALIZADO
    analizado_por_id: Optional[str] = Field(default=None, foreign_key="users.id", index=True)
    fecha_analisis: Optional[str] = Field(default=None)  # YYYY-MM-DD
    # Chlorine analysis (CLORO): numeric value with 1-2 decimals
    cloro_nivel: Optional[float] = Field(default=None)
    # MB, FQ, OTRO: "APTA" or "NO_APTA"
    resultado: Optional[str] = Field(default=None)
    # Protocol number for non-chlorine analyses
    protocolo_numero: Optional[str] = Field(default=None)
    # Optional description for OTRO type
    descripcion: Optional[str] = Field(default=None)
