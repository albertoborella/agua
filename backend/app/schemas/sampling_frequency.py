from pydantic import BaseModel


class SamplingFrequencyCreate(BaseModel):
    fuente_id: str
    tipo_analisis_id: str
    frecuencia: str
    dias_semana: str | None = None
    hora_esperada: str | None = None


class SamplingFrequencyUpdate(BaseModel):
    frecuencia: str | None = None
    dias_semana: str | None = None
    hora_esperada: str | None = None
    activa: bool | None = None


class SamplingFrequencyResponse(BaseModel):
    id: str
    fuente_id: str
    tipo_analisis_id: str
    frecuencia: str
    dias_semana: str | None
    hora_esperada: str | None
    activa: bool
    created_at: str
