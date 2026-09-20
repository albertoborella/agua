from pydantic import BaseModel


class AnalysisTypeCreate(BaseModel):
    codigo: str
    nombre: str
    requiere_descripcion: bool = False


class AnalysisTypeUpdate(BaseModel):
    nombre: str | None = None
    requiere_descripcion: bool | None = None


class AnalysisTypeResponse(BaseModel):
    id: str
    codigo: str
    nombre: str
    requiere_descripcion: bool
