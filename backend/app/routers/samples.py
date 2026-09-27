from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select
from datetime import datetime, timezone, timedelta

from app.database import get_tenant_engine
from app.middleware.auth import get_current_user
from app.models.water_source import WaterSource
from app.models.plant import Plant
from app.models.sampling_frequency import SamplingFrequency
from app.models.water_source import WaterSource
from app.models.plant import Plant
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


@router.get("/counts", response_model=dict)
def get_sample_counts(
    payload: dict = Depends(get_current_user),
):
    """
    Returns counts for dashboard cards:
    - realizadas: total samples in history
    - pendientes: scheduled samples not yet done (based on frequencies)
    - vencidas: overdue samples (past due date, not done)
    """
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        now = datetime.now(timezone.utc)
        today_str = now.strftime("%Y-%m-%d")
        
        # Total realizadas: all samples in history
        from app.models.sample_record import SampleRecord
        total_realizadas = len(session.exec(
            select(SampleRecord).where(SampleRecord.tenant_id == tenant_id)
        ).all())
        
        # Get active frequencies
        frequencies = session.exec(
            select(SamplingFrequency)
            .join(WaterSource, SamplingFrequency.fuente_id == WaterSource.id)
            .join(Plant, WaterSource.planta_id == Plant.id)
            .where(
                Plant.tenant_id == tenant_id,
                SamplingFrequency.activa == True
            )
        ).all()
        
        # Get all existing samples for quick lookup
        existing_samples = session.exec(
            select(SampleRecord).where(SampleRecord.tenant_id == tenant_id)
        ).all()
        
        # Build a set of (fuente_id, tipo_analisis_id, fecha) for quick lookup
        done_samples = set()
        for s in existing_samples:
            key = (s.fuente_id, s.tipo_analisis_id, s.fecha)
            done_samples.add(key)
        
        pendientes = 0
        vencidas = 0
        now_date = now.date()
        
        for freq in frequencies:
            # Calculate expected samples based on frequency
            expected_dates = _get_expected_dates(freq, now_date)
            for expected_date in expected_dates:
                if expected_date > now_date:
                    continue  # Future dates are not counted yet
                key = (freq.fuente_id, freq.tipo_analisis_id, expected_date.strftime("%Y-%m-%d"))
                if key in done_samples:
                    continue  # Already done
                if expected_date < now_date:
                    vencidas += 1
                else:
                    pendientes += 1
        
        return {
            "realizadas": total_realizadas,
            "pendientes": pendientes,
            "vencidas": vencidas,
        }


def _get_expected_dates(freq: SamplingFrequency, until: datetime.date) -> list[datetime.date]:
    """Calculate expected sample dates based on frequency up to a given date."""
    dates = []
    freq_str = freq.frecuencia.lower()
    
    # Parse frequency
    if freq_str in ['daily', 'diario', 'diaria']:
        step = timedelta(days=1)
    elif freq_str in ['weekly', 'semanal']:
        step = timedelta(weeks=1)
    elif freq_str in ['monthly', 'mensual']:
        step = timedelta(days=30)  # Approximation
    elif freq_str in ['semiannual', 'semestral']:
        step = timedelta(days=182)
    elif freq_str in ['annual', 'anual', 'yearly']:
        step = timedelta(days=365)
    else:
        # Try to parse as "Nd" (e.g., "7d", "30d")
        import re
        match = re.match(r'(\d+)d', freq_str)
        if match:
            step = timedelta(days=int(match.group(1)))
        else:
            return []  # Unknown frequency
    
    # For simplicity, start from 30 days ago and generate dates up to today
    start_date = datetime.now(timezone.utc).date() - timedelta(days=30)
    current = start_date
    while current <= datetime.now(timezone.utc).date():
        dates.append(current)
        current += step
    
    return dates
