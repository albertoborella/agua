from pydantic import BaseModel


class AlertResponse(BaseModel):
    id: str
    tenant_id: str
    usuario_id: str
    tipo: str
    fuente_id: str
    tipo_analisis_id: str
    fecha_esperada: str
    leida: bool
    created_at: str
