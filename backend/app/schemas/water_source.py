from pydantic import BaseModel


class WaterSourceCreate(BaseModel):
    planta_id: str
    tipo: str  # GRIFO or POZO
    nombre: str
    ubicacion: str | None = None


class WaterSourceUpdate(BaseModel):
    tipo: str | None = None
    nombre: str | None = None
    ubicacion: str | None = None
    activa: bool | None = None


class WaterSourceResponse(BaseModel):
    id: str
    planta_id: str
    tipo: str
    nombre: str
    ubicacion: str | None
    activa: bool
    created_at: str
