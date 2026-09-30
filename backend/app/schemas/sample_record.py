from pydantic import BaseModel
from datetime import date
from typing import Optional


class SampleRecordCreate(BaseModel):
    fuente_id: str
    tipo_analisis_id: str


class SampleRecordResponse(BaseModel):
    id: str
    tenant_id: str
    fuente_id: str
    tipo_analisis_id: str
    operario_id: str
    fecha: str
    hora: str
    sincronizada: bool
    created_at: str


class ScheduledSampleResponse(BaseModel):
    """A sample that is scheduled but not yet taken."""
    frecuencia_id: str
    fuente_id: str
    fuente_nombre: str
    fuente_tipo: str
    tipo_analisis_id: str
    tipo_analisis_nombre: str
    tipo_analisis_codigo: str
    fecha_programada: date
    dias_desde_programada: int
    estado: str  # "PENDIENTE" or "VENCIDA"


class TakeScheduledSampleRequest(BaseModel):
    """Request to take a scheduled sample."""
    frecuencia_id: str
    fuente_id: str
    tipo_analisis_id: str
