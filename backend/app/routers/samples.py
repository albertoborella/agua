from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select
from datetime import datetime, timezone, timedelta, date

from app.database import get_tenant_engine, get_global_engine
from app.middleware.auth import get_current_user
from app.models.water_source import WaterSource
from app.models.plant import Plant
from app.models.sampling_frequency import SamplingFrequency
from app.models.analysis_type import AnalysisType
from app.models.sample_record import SampleRecord
from app.schemas.sample_record import (
    SampleRecordCreate,
    SampleRecordResponse,
    ScheduledSampleResponse,
    TakeScheduledSampleRequest,
)
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
    """Create an ad-hoc sample (not scheduled)."""
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


@router.post("/take-scheduled", response_model=SampleRecordResponse)
def take_scheduled_sample(
    data: TakeScheduledSampleRequest,
    payload: dict = Depends(get_current_user),
):
    """
    Take a scheduled sample (from pending or overdue).
    Creates a SampleRecord with today's date/time.
    """
    tenant_id = payload["tenant"]
    user_id = payload["sub"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        # Verify the frequency exists and is active
        freq = session.get(SamplingFrequency, data.frecuencia_id)
        if not freq:
            raise HTTPException(status_code=404, detail="Frecuencia no encontrada")
        if not freq.activa:
            raise HTTPException(status_code=400, detail="Frecuencia inactiva")
        
        # Verify frequency matches the source and analysis type
        if freq.fuente_id != data.fuente_id:
            raise HTTPException(status_code=400, detail="La frecuencia no corresponde a la fuente indicada")
        if freq.tipo_analisis_id != data.tipo_analisis_id:
            raise HTTPException(status_code=400, detail="La frecuencia no corresponde al tipo de análisis indicado")
        
        # Verify source exists and is active
        source = session.get(WaterSource, data.fuente_id)
        if not source or not source.activa:
            raise HTTPException(status_code=404, detail="Fuente no encontrada o inactiva")
        
        # Create sample with today's date/time
        svc = SampleService(session)
        now = datetime.now(timezone.utc)
        sample = svc.repo.create({
            "tenant_id": tenant_id,
            "fuente_id": data.fuente_id,
            "tipo_analisis_id": data.tipo_analisis_id,
            "operario_id": user_id,
            "fecha": now.strftime("%Y-%m-%d"),
            "hora": now.strftime("%H:%M:%S"),
        })
        return SampleRecordResponse(**sample.model_dump())


@router.get("/pending", response_model=list[ScheduledSampleResponse])
def get_pending_samples(
    payload: dict = Depends(get_current_user),
):
    """
    Get scheduled samples that are PENDIENTE (due today or within 15 days, not yet taken).
    """
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        return _get_scheduled_samples(session, tenant_id, estado="PENDIENTE")


@router.get("/overdue", response_model=list[ScheduledSampleResponse])
def get_overdue_samples(
    payload: dict = Depends(get_current_user),
):
    """
    Get scheduled samples that are VENCIDA (overdue by more than 15 days, not yet taken).
    """
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        return _get_scheduled_samples(session, tenant_id, estado="VENCIDA")


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
    Returns counts for dashboard cards with 15-day rule:
    - realizadas: total samples in history
    - pendientes: scheduled samples not yet done, due within 15 days (including today)
    - vencidas: scheduled samples not yet done, overdue by more than 15 days
    """
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        now = datetime.now(timezone.utc)
        today = now.date()
        cutoff_pending = today + timedelta(days=15)
        
        # Total realizadas: all samples in history
        total_realizadas = len(session.exec(
            select(SampleRecord).where(SampleRecord.tenant_id == tenant_id)
        ).all())
        
        # Get active frequencies with joins for source and analysis type info
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
        
        for freq in frequencies:
            # Calculate expected samples based on frequency
            expected_dates = _get_expected_dates(freq, cutoff_pending)
            for expected_date in expected_dates:
                if expected_date > cutoff_pending:
                    continue  # Beyond 15 days - not counted yet
                key = (freq.fuente_id, freq.tipo_analisis_id, expected_date.strftime("%Y-%m-%d"))
                if key in done_samples:
                    continue  # Already done
                if expected_date > today:
                    # Future date within 15 days = PENDIENTE
                    pendientes += 1
                elif expected_date == today:
                    # Due today = PENDIENTE
                    pendientes += 1
                else:
                    # Past due
                    days_overdue = (today - expected_date).days
                    if days_overdue <= 15:
                        # Within 15 days overdue = PENDIENTE
                        pendientes += 1
                    else:
                        # More than 15 days overdue = VENCIDA
                        vencidas += 1
        
        return {
            "realizadas": total_realizadas,
            "pendientes": pendientes,
            "vencidas": vencidas,
        }


def _get_scheduled_samples(
    session: Session, 
    tenant_id: str, 
    estado: str
) -> list[ScheduledSampleResponse]:
    """
    Get scheduled samples (pending or overdue) with full details.
    """
    now = datetime.now(timezone.utc)
    today = now.date()
    cutoff_pending = today + timedelta(days=15)
    
    # Get active frequencies with joins for source and plant (tenant DB)
    frequencies = session.exec(
        select(SamplingFrequency, WaterSource, Plant)
        .join(WaterSource, SamplingFrequency.fuente_id == WaterSource.id)
        .join(Plant, WaterSource.planta_id == Plant.id)
        .where(
            Plant.tenant_id == tenant_id,
            SamplingFrequency.activa == True,
            WaterSource.activa == True,
        )
    ).all()
    
    # Get analysis types from global database
    global_engine = get_global_engine()
    with Session(global_engine) as global_session:
        analysis_types = global_session.exec(select(AnalysisType)).all()
        # Build a dict for quick lookup
        analysis_type_map = {at.id: at for at in analysis_types}
    
    # Get all existing samples for quick lookup
    existing_samples = session.exec(
        select(SampleRecord).where(SampleRecord.tenant_id == tenant_id)
    ).all()
    
    done_samples = set()
    for s in existing_samples:
        key = (s.fuente_id, s.tipo_analisis_id, s.fecha)
        done_samples.add(key)
    
    results = []
    
    for freq, source, plant in frequencies:
        analysis_type = analysis_type_map.get(freq.tipo_analisis_id)
        if not analysis_type:
            continue  # Skip if analysis type not found
        
        expected_dates = _get_expected_dates(freq, cutoff_pending)
        for expected_date in expected_dates:
            if expected_date > cutoff_pending:
                continue
            key = (freq.fuente_id, freq.tipo_analisis_id, expected_date.strftime("%Y-%m-%d"))
            if key in done_samples:
                continue
            
            if expected_date > today:
                # Future date within 15 days
                if estado == "PENDIENTE":
                    dias = (expected_date - today).days
                    results.append(ScheduledSampleResponse(
                        frecuencia_id=freq.id,
                        fuente_id=source.id,
                        fuente_nombre=source.nombre,
                        fuente_tipo=source.tipo,
                        tipo_analisis_id=analysis_type.id,
                        tipo_analisis_nombre=analysis_type.nombre,
                        tipo_analisis_codigo=analysis_type.codigo,
                        fecha_programada=expected_date,
                        dias_desde_programada=-dias,  # Negative = days until due
                        estado="PENDIENTE",
                    ))
            elif expected_date == today:
                # Due today
                if estado == "PENDIENTE":
                    results.append(ScheduledSampleResponse(
                        frecuencia_id=freq.id,
                        fuente_id=source.id,
                        fuente_nombre=source.nombre,
                        fuente_tipo=source.tipo,
                        tipo_analisis_id=analysis_type.id,
                        tipo_analisis_nombre=analysis_type.nombre,
                        tipo_analisis_codigo=analysis_type.codigo,
                        fecha_programada=expected_date,
                        dias_desde_programada=0,
                        estado="PENDIENTE",
                    ))
            else:
                # Past due
                days_overdue = (today - expected_date).days
                if days_overdue <= 15:
                    # Within 15 days overdue = PENDIENTE
                    if estado == "PENDIENTE":
                        results.append(ScheduledSampleResponse(
                            frecuencia_id=freq.id,
                            fuente_id=source.id,
                            fuente_nombre=source.nombre,
                            fuente_tipo=source.tipo,
                            tipo_analisis_id=analysis_type.id,
                            tipo_analisis_nombre=analysis_type.nombre,
                            tipo_analisis_codigo=analysis_type.codigo,
                            fecha_programada=expected_date,
                            dias_desde_programada=days_overdue,
                            estado="PENDIENTE",
                        ))
                else:
                    # More than 15 days overdue = VENCIDA
                    if estado == "VENCIDA":
                        results.append(ScheduledSampleResponse(
                            frecuencia_id=freq.id,
                            fuente_id=source.id,
                            fuente_nombre=source.nombre,
                            fuente_tipo=source.tipo,
                            tipo_analisis_id=analysis_type.id,
                            tipo_analisis_nombre=analysis_type.nombre,
                            tipo_analisis_codigo=analysis_type.codigo,
                            fecha_programada=expected_date,
                            dias_desde_programada=days_overdue,
                            estado="VENCIDA",
                        ))
    
    # Sort by fecha_programada (oldest first for overdue, nearest first for pending)
    if estado == "VENCIDA":
        results.sort(key=lambda x: x.fecha_programada)
    else:
        results.sort(key=lambda x: x.fecha_programada)
    
    return results


def _get_expected_dates(freq: SamplingFrequency, until: date) -> list[date]:
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
    while current <= until:
        dates.append(current)
        current += step
    
    return dates