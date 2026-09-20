from datetime import datetime, timezone

from sqlmodel import Session, select

from app.models.sample_record import SampleRecord
from app.repositories.base import BaseRepository


class SampleService:
    def __init__(self, session: Session):
        self.repo = BaseRepository(SampleRecord, session)
        self.session = session

    def create_sample(self, tenant_id: str, fuente_id: str, tipo_analisis_id: str, operario_id: str) -> SampleRecord:
        now = datetime.now(timezone.utc)
        return self.repo.create(
            {
                "tenant_id": tenant_id,
                "fuente_id": fuente_id,
                "tipo_analisis_id": tipo_analisis_id,
                "operario_id": operario_id,
                "fecha": now.strftime("%Y-%m-%d"),
                "hora": now.strftime("%H:%M:%S"),
            }
        )

    def get_today(self, tenant_id: str, operario_id: str):
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        return self.session.exec(
            select(SampleRecord).where(
                SampleRecord.tenant_id == tenant_id,
                SampleRecord.operario_id == operario_id,
                SampleRecord.fecha == today,
            )
        ).all()

    def get_history(
        self,
        tenant_id: str,
        fuente_id: str | None = None,
        tipo_analisis_id: str | None = None,
        fecha_desde: str | None = None,
        fecha_hasta: str | None = None,
    ):
        stmt = select(SampleRecord).where(SampleRecord.tenant_id == tenant_id)
        if fuente_id:
            stmt = stmt.where(SampleRecord.fuente_id == fuente_id)
        if tipo_analisis_id:
            stmt = stmt.where(SampleRecord.tipo_analisis_id == tipo_analisis_id)
        if fecha_desde:
            stmt = stmt.where(SampleRecord.fecha >= fecha_desde)
        if fecha_hasta:
            stmt = stmt.where(SampleRecord.fecha <= fecha_hasta)
        return self.session.exec(stmt).all()
