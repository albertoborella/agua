from pydantic import BaseModel


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
