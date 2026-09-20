from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from app.database import get_tenant_engine
from app.middleware.auth import require_role
from app.schemas.analysis_type import AnalysisTypeCreate, AnalysisTypeUpdate, AnalysisTypeResponse
from app.schemas.plant import PlantCreate, PlantUpdate, PlantResponse
from app.schemas.sampling_frequency import (
    SamplingFrequencyCreate,
    SamplingFrequencyUpdate,
    SamplingFrequencyResponse,
)
from app.schemas.user import UserCreate, UserUpdate, UserResponse, ResetPasswordRequest
from app.schemas.water_source import WaterSourceCreate, WaterSourceUpdate, WaterSourceResponse
from app.services.config_service import (
    AnalysisTypeService,
    PlantService,
    SamplingFrequencyService,
    WaterSourceService,
)
from app.services.user_service import UserService

router = APIRouter(prefix="/admin", tags=["admin"])


# ─── Plants ──────────────────────────────────────────────────────────

@router.post("/plants", response_model=PlantResponse)
def create_plant(
    data: PlantCreate,
    payload: dict = Depends(require_role(["ADMIN"])),
    tenant_id: str = Depends(lambda payload=Depends(require_role(["ADMIN"])): payload["tenant"]),
):
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = PlantService(session)
        plant = svc.create(tenant_id=tenant_id, **data.model_dump())
        return PlantResponse(**plant.model_dump())


@router.get("/plants", response_model=list[PlantResponse])
def list_plants(
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = PlantService(session)
        plants = svc.list(tenant_id)
        return [PlantResponse(**p.model_dump()) for p in plants]


@router.put("/plants/{plant_id}", response_model=PlantResponse)
def update_plant(
    plant_id: str,
    data: PlantUpdate,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = PlantService(session)
        plant = svc.update(tenant_id, plant_id, **data.model_dump(exclude_unset=True))
        if not plant:
            raise HTTPException(status_code=404, detail="Planta no encontrada")
        return PlantResponse(**plant.model_dump())


@router.delete("/plants/{plant_id}")
def delete_plant(
    plant_id: str,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = PlantService(session)
        if not svc.delete(tenant_id, plant_id):
            raise HTTPException(status_code=404, detail="Planta no encontrada")
        return {"message": "Planta eliminada"}


# ─── Water Sources ───────────────────────────────────────────────────

@router.post("/sources", response_model=WaterSourceResponse)
def create_source(
    data: WaterSourceCreate,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = WaterSourceService(session)
        source = svc.create(**data.model_dump())
        return WaterSourceResponse(**source.model_dump())


@router.get("/sources", response_model=list[WaterSourceResponse])
def list_sources(
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        from sqlmodel import select
        from app.models.water_source import WaterSource

        sources = session.exec(select(WaterSource).where(WaterSource.activa == True)).all()
        return [WaterSourceResponse(**s.model_dump()) for s in sources]


@router.put("/sources/{source_id}", response_model=WaterSourceResponse)
def update_source(
    source_id: str,
    data: WaterSourceUpdate,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = WaterSourceService(session)
        source = svc.update(source_id, **data.model_dump(exclude_unset=True))
        if not source:
            raise HTTPException(status_code=404, detail="Fuente no encontrada")
        return WaterSourceResponse(**source.model_dump())


@router.delete("/sources/{source_id}")
def delete_source(
    source_id: str,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = WaterSourceService(session)
        if not svc.delete(source_id):
            raise HTTPException(status_code=404, detail="Fuente no encontrada")
        return {"message": "Fuente eliminada"}


# ─── Analysis Types (global catalog) ─────────────────────────────────

@router.post("/analysis-types", response_model=AnalysisTypeResponse)
def create_analysis_type(
    data: AnalysisTypeCreate,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    from app.database import get_global_engine
    engine = get_global_engine()
    with Session(engine) as session:
        svc = AnalysisTypeService(session)
        atype = svc.create(**data.model_dump())
        return AnalysisTypeResponse(**atype.model_dump())


@router.get("/analysis-types", response_model=list[AnalysisTypeResponse])
def list_analysis_types(
    payload: dict = Depends(require_role(["ADMIN"])),
):
    from app.database import get_global_engine
    engine = get_global_engine()
    with Session(engine) as session:
        svc = AnalysisTypeService(session)
        types = svc.list_all()
        return [AnalysisTypeResponse(**t.model_dump()) for t in types]


@router.put("/analysis-types/{type_id}", response_model=AnalysisTypeResponse)
def update_analysis_type(
    type_id: str,
    data: AnalysisTypeUpdate,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    from app.database import get_global_engine
    engine = get_global_engine()
    with Session(engine) as session:
        svc = AnalysisTypeService(session)
        atype = svc.update(type_id, **data.model_dump(exclude_unset=True))
        if not atype:
            raise HTTPException(status_code=404, detail="Tipo de análisis no encontrado")
        return AnalysisTypeResponse(**atype.model_dump())


@router.delete("/analysis-types/{type_id}")
def delete_analysis_type(
    type_id: str,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    from app.database import get_global_engine
    engine = get_global_engine()
    with Session(engine) as session:
        svc = AnalysisTypeService(session)
        if not svc.delete(type_id):
            raise HTTPException(status_code=404, detail="Tipo de análisis no encontrado")
        return {"message": "Tipo de análisis eliminado"}


# ─── Sampling Frequencies ────────────────────────────────────────────

@router.post("/frequencies", response_model=SamplingFrequencyResponse)
def create_frequency(
    data: SamplingFrequencyCreate,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = SamplingFrequencyService(session)
        freq = svc.create(**data.model_dump())
        return SamplingFrequencyResponse(**freq.model_dump())


@router.get("/frequencies", response_model=list[SamplingFrequencyResponse])
def list_frequencies(
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        from sqlmodel import select
        from app.models.sampling_frequency import SamplingFrequency

        freqs = session.exec(select(SamplingFrequency).where(SamplingFrequency.activa == True)).all()
        return [SamplingFrequencyResponse(**f.model_dump()) for f in freqs]


@router.put("/frequencies/{freq_id}", response_model=SamplingFrequencyResponse)
def update_frequency(
    freq_id: str,
    data: SamplingFrequencyUpdate,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = SamplingFrequencyService(session)
        freq = svc.update(freq_id, **data.model_dump(exclude_unset=True))
        if not freq:
            raise HTTPException(status_code=404, detail="Frecuencia no encontrada")
        return SamplingFrequencyResponse(**freq.model_dump())


@router.delete("/frequencies/{freq_id}")
def delete_frequency(
    freq_id: str,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = SamplingFrequencyService(session)
        if not svc.delete(freq_id):
            raise HTTPException(status_code=404, detail="Frecuencia no encontrada")
        return {"message": "Frecuencia eliminada"}


# ─── Users ───────────────────────────────────────────────────────────

@router.post("/users", response_model=UserResponse)
def create_user(
    data: UserCreate,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = UserService(session)
        user = svc.create_user(tenant_id, data.username, data.email, data.password, data.rol)
        return UserResponse(**user.model_dump())


@router.get("/users", response_model=list[UserResponse])
def list_users(
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = UserService(session)
        users = svc.list_users(tenant_id)
        return [UserResponse(**u.model_dump()) for u in users]


@router.put("/users/{user_id}", response_model=UserResponse)
def update_user(
    user_id: str,
    data: UserUpdate,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = UserService(session)
        user = svc.update_user(tenant_id, user_id, **data.model_dump(exclude_unset=True))
        if not user:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        return UserResponse(**user.model_dump())


@router.delete("/users/{user_id}")
def delete_user(
    user_id: str,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = UserService(session)
        if not svc.delete_user(tenant_id, user_id):
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        return {"message": "Usuario eliminado"}


@router.post("/users/{user_id}/reset-password")
def reset_user_password(
    user_id: str,
    data: ResetPasswordRequest,
    payload: dict = Depends(require_role(["ADMIN"])),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = UserService(session)
        user = svc.reset_password(tenant_id, user_id, data.new_password)
        if not user:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        return {"message": "Contraseña restablecida"}
