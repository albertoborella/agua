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
    # Lab analysis fields
    estado_analisis: str
    analizado_por_id: Optional[str] = None
    fecha_analisis: Optional[str] = None
    cloro_nivel: Optional[float] = None
    resultado: Optional[str] = None
    protocolo_numero: Optional[str] = None
    descripcion: Optional[str] = None


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


# Lab analysis schemas
class LabSampleResponse(BaseModel):
    """Sample waiting for or already analyzed by lab."""
    id: str
    tenant_id: str
    fuente_id: str
    fuente_nombre: str
    fuente_tipo: str
    tipo_analisis_id: str
    tipo_analisis_nombre: str
    tipo_analisis_codigo: str
    operario_id: str
    operario_username: str
    fecha: str
    hora: str
    sincronizada: bool
    created_at: str
    estado_analisis: str
    analizado_por_id: Optional[str] = None
    fecha_analisis: Optional[str] = None
    cloro_nivel: Optional[float] = None
    resultado: Optional[str] = None
    protocolo_numero: Optional[str] = None
    descripcion: Optional[str] = None


class LabSampleCounts(BaseModel):
    """Counts for lab dashboard."""
    pendientes_analisis: int
    analizadas: int
    total: int


class CloroAnalysisRequest(BaseModel):
    """Request to submit chlorine analysis result."""
    cloro_nivel: float  # 1-2 decimals


class GeneralAnalysisRequest(BaseModel):
    """Request to submit MB/FQ/OTRO analysis result."""
    resultado: str  # "APTA" or "NO_APTA"
    protocolo_numero: str
    descripcion: Optional[str] = None
