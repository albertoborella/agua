from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select

from app.database import get_tenant_engine
from app.middleware.auth import get_current_user
from app.models.water_source import WaterSource
from app.schemas.sample_record import SampleRecordCreate, SampleRecordResponse
from app.services.sample_service import SampleService

router = APIRouter(prefix="/samples", tags=["samples"])


@router.get("/sources")
def list_sources(
    payload: dict = Depends(get_current_user),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        sources = session.exec(
            select(WaterSource).where(WaterSource.activa == True)
        ).all()
        return [
            {"id": s.id, "nombre": s.nombre, "tipo": s.tipo}
            for s in sources
        ]


@router.post("", response_model=SampleRecordResponse)
def create_sample(
    data: SampleRecordCreate,
    payload: dict = Depends(get_current_user),
):
    tenant_id = payload["tenant"]
    user_id = payload["sub"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = SampleService(session)
        sample = svc.create_sample(
            tenant_id=tenant_id,
            fuente_id=data.fuente_id,
            tipo_analisis_id=data.tipo_analisis_id,
            operario_id=user_id,
        )
        return SampleRecordResponse(**sample.model_dump())


@router.get("/today", response_model=list[SampleRecordResponse])
def get_today_samples(
    payload: dict = Depends(get_current_user),
):
    tenant_id = payload["tenant"]
    user_id = payload["sub"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = SampleService(session)
        samples = svc.get_today(tenant_id, user_id)
        return [SampleRecordResponse(**s.model_dump()) for s in samples]


@router.get("/history", response_model=list[SampleRecordResponse])
def get_history(
    fuente_id: str | None = Query(None),
    tipo_analisis_id: str | None = Query(None),
    fecha_desde: str | None = Query(None),
    fecha_hasta: str | None = Query(None),
    payload: dict = Depends(get_current_user),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = SampleService(session)
        samples = svc.get_history(
            tenant_id,
            fuente_id=fuente_id,
            tipo_analisis_id=tipo_analisis_id,
            fecha_desde=fecha_desde,
            fecha_hasta=fecha_hasta,
        )
        return [SampleRecordResponse(**s.model_dump()) for s in samples]
