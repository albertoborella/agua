from sqlmodel import Session, select

from app.models.analysis_type import AnalysisType
from app.models.plant import Plant
from app.models.sampling_frequency import SamplingFrequency
from app.models.water_source import WaterSource
from app.repositories.base import BaseRepository


class PlantService:
    def __init__(self, session: Session):
        self.repo = BaseRepository(Plant, session)

    def create(self, tenant_id: str, **kwargs) -> Plant:
        return self.repo.create({"tenant_id": tenant_id, **kwargs})

    def get(self, tenant_id: str, plant_id: str) -> Plant | None:
        return self.repo.get_by_tenant(tenant_id, plant_id)

    def list(self, tenant_id: str, skip: int = 0, limit: int = 100):
        return self.repo.list_by_tenant(tenant_id, skip, limit)

    def update(self, tenant_id: str, plant_id: str, **kwargs) -> Plant | None:
        return self.repo.update(plant_id, kwargs)

    def delete(self, tenant_id: str, plant_id: str) -> bool:
        return self.repo.delete(plant_id)


class WaterSourceService:
    def __init__(self, session: Session):
        self.repo = BaseRepository(WaterSource, session)
        self.session = session

    def create(self, **kwargs) -> WaterSource:
        return self.repo.create(kwargs)

    def get(self, source_id: str) -> WaterSource | None:
        return self.repo.get(source_id)

    def list_by_plant(self, planta_id: str):
        return self.session.exec(
            select(WaterSource).where(WaterSource.planta_id == planta_id, WaterSource.activa == True)
        ).all()

    def update(self, source_id: str, **kwargs) -> WaterSource | None:
        return self.repo.update(source_id, kwargs)

    def delete(self, source_id: str) -> bool:
        return self.repo.delete(source_id)


class AnalysisTypeService:
    def __init__(self, session: Session):
        self.repo = BaseRepository(AnalysisType, session)
        self.session = session

    def create(self, **kwargs) -> AnalysisType:
        return self.repo.create(kwargs)

    def get(self, type_id: str) -> AnalysisType | None:
        return self.repo.get(type_id)

    def list_all(self):
        return self.session.exec(select(AnalysisType)).all()

    def update(self, type_id: str, **kwargs) -> AnalysisType | None:
        return self.repo.update(type_id, kwargs)

    def delete(self, type_id: str) -> bool:
        return self.repo.delete(type_id)


class SamplingFrequencyService:
    def __init__(self, session: Session):
        self.repo = BaseRepository(SamplingFrequency, session)
        self.session = session

    def create(self, **kwargs) -> SamplingFrequency:
        return self.repo.create(kwargs)

    def get(self, freq_id: str) -> SamplingFrequency | None:
        return self.repo.get(freq_id)

    def list_by_source(self, fuente_id: str):
        return self.session.exec(
            select(SamplingFrequency).where(
                SamplingFrequency.fuente_id == fuente_id,
                SamplingFrequency.activa == True,
            )
        ).all()

    def update(self, freq_id: str, **kwargs) -> SamplingFrequency | None:
        return self.repo.update(freq_id, kwargs)

    def delete(self, freq_id: str) -> bool:
        return self.repo.delete(freq_id)
