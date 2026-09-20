from pydantic import BaseModel


class PlantCreate(BaseModel):
    nombre: str
    direccion: str | None = None


class PlantUpdate(BaseModel):
    nombre: str | None = None
    direccion: str | None = None
    activa: bool | None = None


class PlantResponse(BaseModel):
    id: str
    tenant_id: str
    nombre: str
    direccion: str | None
    activa: bool
    created_at: str
