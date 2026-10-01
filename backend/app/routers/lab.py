from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import Session, select
from datetime import datetime, timezone

from app.database import get_tenant_engine, get_global_engine
from app.middleware.auth import get_current_user
from app.models.water_source import WaterSource
from app.models.plant import Plant
from app.models.analysis_type import AnalysisType
from app.models.sample_record import SampleRecord
from app.models.user import User
from app.schemas.sample_record import (
    LabSampleResponse,
    LabSampleCounts,
    CloroAnalysisRequest,
    GeneralAnalysisRequest,
)

router = APIRouter(prefix="/lab", tags=["lab"])


def require_laboratorista(payload: dict = Depends(get_current_user)):
    """Dependency to ensure user has LABORATORISTA role."""
    if payload.get("rol") != "LABORATORISTA":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado: se requiere rol LABORATORISTA",
        )
    return payload


@router.get("/samples", response_model=list[LabSampleResponse])
def get_lab_samples(
    estado_analisis: str | None = Query("PENDIENTE", description="Filter by analysis state: PENDIENTE or ANALIZADO. Defaults to PENDIENTE"),
    tipo_analisis_codigo: str | None = Query(None, description="Filter by analysis type code (CLORO, FQ, MB, OTRO)"),
    fuente_id: str | None = Query(None, description="Filter by water source ID"),
    fecha_desde: str | None = Query(None, description="Filter by sample date from (YYYY-MM-DD)"),
    fecha_hasta: str | None = Query(None, description="Filter by sample date to (YYYY-MM-DD)"),
    payload: dict = Depends(require_laboratorista),
):
    """
    Get samples for the lab with their analysis status.
    Defaults to PENDIENTE samples. For history (ANALIZADO), supports date range, type and source filters.
    Only accessible by LABORATORISTA role.
    """
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        # Get all samples for this tenant
        query = select(SampleRecord).where(SampleRecord.tenant_id == tenant_id)
        
        # Default to PENDIENTE if not specified
        if estado_analisis:
            query = query.where(SampleRecord.estado_analisis == estado_analisis)
        
        # Date range filters (apply to sample fecha field)
        if fecha_desde:
            query = query.where(SampleRecord.fecha >= fecha_desde)
        if fecha_hasta:
            query = query.where(SampleRecord.fecha <= fecha_hasta)
        
        # Source filter
        if fuente_id:
            query = query.where(SampleRecord.fuente_id == fuente_id)
        
        samples = session.exec(query).all()
        
        # Get related data from global DB
        global_engine = get_global_engine()
        with Session(global_engine) as global_session:
            # Get analysis types
            analysis_types = global_session.exec(select(AnalysisType)).all()
            analysis_type_map = {at.id: at for at in analysis_types}
            
            # Get water sources and plants
            sources = session.exec(
                select(WaterSource, Plant)
                .join(Plant, WaterSource.planta_id == Plant.id)
                .where(Plant.tenant_id == tenant_id)
            ).all()
            source_map = {s.id: (s, p) for s, p in sources}
            
            # Get users (operarios)
            users = session.exec(select(User).where(User.tenant_id == tenant_id)).all()
            user_map = {u.id: u for u in users}
        
        results = []
        for sample in samples:
            analysis_type = analysis_type_map.get(sample.tipo_analisis_id)
            if not analysis_type:
                continue
            
            source_data = source_map.get(sample.fuente_id)
            if not source_data:
                continue
            source, plant = source_data
            
            operario = user_map.get(sample.operario_id)
            
            # Filter by tipo_analisis_codigo if provided
            if tipo_analisis_codigo and analysis_type.codigo != tipo_analisis_codigo:
                continue
            
            results.append(LabSampleResponse(
                id=sample.id,
                tenant_id=sample.tenant_id,
                fuente_id=sample.fuente_id,
                fuente_nombre=source.nombre,
                fuente_tipo=source.tipo,
                tipo_analisis_id=sample.tipo_analisis_id,
                tipo_analisis_nombre=analysis_type.nombre,
                tipo_analisis_codigo=analysis_type.codigo,
                operario_id=sample.operario_id,
                operario_username=operario.username if operario else "Desconocido",
                fecha=sample.fecha,
                hora=sample.hora,
                sincronizada=sample.sincronizada,
                created_at=sample.created_at,
                estado_analisis=sample.estado_analisis,
                analizado_por_id=sample.analizado_por_id,
                fecha_analisis=sample.fecha_analisis,
                cloro_nivel=sample.cloro_nivel,
                resultado=sample.resultado,
                protocolo_numero=sample.protocolo_numero,
                descripcion=sample.descripcion,
            ))
        
        # Sort by created_at descending (newest first)
        results.sort(key=lambda x: x.created_at, reverse=True)
        return results


@router.get("/counts", response_model=LabSampleCounts)
def get_lab_counts(
    payload: dict = Depends(require_laboratorista),
):
    """Get counts for lab dashboard."""
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        all_samples = session.exec(
            select(SampleRecord).where(SampleRecord.tenant_id == tenant_id)
        ).all()
        
        pendientes = sum(1 for s in all_samples if s.estado_analisis == "PENDIENTE")
        analizadas = sum(1 for s in all_samples if s.estado_analisis == "ANALIZADO")
        
        return LabSampleCounts(
            pendientes_analisis=pendientes,
            analizadas=analizadas,
            total=len(all_samples),
        )


@router.post("/samples/{sample_id}/analyze/cloro", response_model=LabSampleResponse)
def submit_cloro_analysis(
    sample_id: str,
    data: CloroAnalysisRequest,
    payload: dict = Depends(require_laboratorista),
):
    """Submit chlorine analysis result (numeric value with 1-2 decimals)."""
    tenant_id = payload["tenant"]
    user_id = payload["sub"]
    engine = get_tenant_engine(tenant_id)
    
    with Session(engine) as session:
        sample = session.get(SampleRecord, sample_id)
        if not sample:
            raise HTTPException(status_code=404, detail="Muestra no encontrada")
        if sample.tenant_id != tenant_id:
            raise HTTPException(status_code=403, detail="Muestra no pertenece a este tenant")
        
        # Verify it's a chlorine analysis
        global_engine = get_global_engine()
        with Session(global_engine) as global_session:
            analysis_type = global_session.get(AnalysisType, sample.tipo_analisis_id)
            if not analysis_type or analysis_type.codigo != "CLORO":
                raise HTTPException(
                    status_code=400,
                    detail="Esta muestra no es de tipo CLORO",
                )
        
        # Validate chlorine level (1-2 decimals)
        cloro_value = round(data.cloro_nivel, 2)
        if cloro_value < 0:
            raise HTTPException(
                status_code=400,
                detail="El nivel de cloro no puede ser negativo",
            )
        
        # Update sample
        sample.estado_analisis = "ANALIZADO"
        sample.analizado_por_id = user_id
        sample.fecha_analisis = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        sample.cloro_nivel = cloro_value
        sample.resultado = None
        sample.protocolo_numero = None
        sample.descripcion = None
        
        session.add(sample)
        session.commit()
        session.refresh(sample)
        
        # Return enriched response
        return _build_lab_response(sample, session, global_engine)


@router.post("/samples/{sample_id}/analyze/general", response_model=LabSampleResponse)
def submit_general_analysis(
    sample_id: str,
    data: GeneralAnalysisRequest,
    payload: dict = Depends(require_laboratorista),
):
    """Submit MB/FQ/OTRO analysis result (APTA/NO_APTA + protocol number)."""
    tenant_id = payload["tenant"]
    user_id = payload["sub"]
    engine = get_tenant_engine(tenant_id)
    
    with Session(engine) as session:
        sample = session.get(SampleRecord, sample_id)
        if not sample:
            raise HTTPException(status_code=404, detail="Muestra no encontrada")
        if sample.tenant_id != tenant_id:
            raise HTTPException(status_code=403, detail="Muestra no pertenece a este tenant")
        
        # Verify it's NOT a chlorine analysis
        global_engine = get_global_engine()
        with Session(global_engine) as global_session:
            analysis_type = global_session.get(AnalysisType, sample.tipo_analisis_id)
            if not analysis_type or analysis_type.codigo == "CLORO":
                raise HTTPException(
                    status_code=400,
                    detail="Esta muestra es de tipo CLORO, use el endpoint correspondiente",
                )
        
        # Validate resultado
        resultado_upper = data.resultado.upper().strip()
        if resultado_upper not in ["APTA", "NO_APTA"]:
            raise HTTPException(
                status_code=400,
                detail="El resultado debe ser 'APTA' o 'NO_APTA'",
            )
        
        # Validate protocol number
        if not data.protocolo_numero or not data.protocolo_numero.strip():
            raise HTTPException(
                status_code=400,
                detail="El número de protocolo es obligatorio",
            )
        
        # Update sample
        sample.estado_analisis = "ANALIZADO"
        sample.analizado_por_id = user_id
        sample.fecha_analisis = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        sample.resultado = resultado_upper
        sample.protocolo_numero = data.protocolo_numero.strip()
        sample.descripcion = data.descripcion.strip() if data.descripcion else None
        sample.cloro_nivel = None
        
        session.add(sample)
        session.commit()
        session.refresh(sample)
        
        # Return enriched response
        return _build_lab_response(sample, session, global_engine)


def _build_lab_response(
    sample: SampleRecord,
    session: Session,
    global_engine,
) -> LabSampleResponse:
    """Build enriched LabSampleResponse from sample."""
    with Session(global_engine) as global_session:
        analysis_type = global_session.get(AnalysisType, sample.tipo_analisis_id)
        sources = session.exec(
            select(WaterSource, Plant)
            .join(Plant, WaterSource.planta_id == Plant.id)
            .where(Plant.tenant_id == sample.tenant_id)
        ).all()
        source_map = {s.id: (s, p) for s, p in sources}
        users = session.exec(select(User).where(User.tenant_id == sample.tenant_id)).all()
        user_map = {u.id: u for u in users}
    
    source_data = source_map.get(sample.fuente_id)
    if not source_data:
        raise HTTPException(status_code=404, detail="Fuente no encontrada")
    source, plant = source_data
    
    operario = user_map.get(sample.operario_id)
    
    return LabSampleResponse(
        id=sample.id,
        tenant_id=sample.tenant_id,
        fuente_id=sample.fuente_id,
        fuente_nombre=source.nombre,
        fuente_tipo=source.tipo,
        tipo_analisis_id=sample.tipo_analisis_id,
        tipo_analisis_nombre=analysis_type.nombre if analysis_type else "Desconocido",
        tipo_analisis_codigo=analysis_type.codigo if analysis_type else "DESCONOCIDO",
        operario_id=sample.operario_id,
        operario_username=operario.username if operario else "Desconocido",
        fecha=sample.fecha,
        hora=sample.hora,
        sincronizada=sample.sincronizada,
        created_at=sample.created_at,
        estado_analisis=sample.estado_analisis,
        analizado_por_id=sample.analizado_por_id,
        fecha_analisis=sample.fecha_analisis,
        cloro_nivel=sample.cloro_nivel,
        resultado=sample.resultado,
        protocolo_numero=sample.protocolo_numero,
        descripcion=sample.descripcion,
    )