"""Catalog routes.

The analysis-type catalog is global reference data: the table has no
`tenant_id` and lives in the global database, so the same four rows apply to
every company. Reading it exposes nothing tenant-specific, which is why it is
open to any authenticated user rather than gated behind ADMIN like the
write routes in `admin.py`.

This is the endpoint described in docs/architecture/01-api-design.md
("Catalogos -> GET /catalog/analysis-types, Auth: Cualquier usuario"); the
implementation had drifted to an ADMIN-only route under /admin.
"""

from fastapi import APIRouter, Depends
from sqlmodel import Session

from app.database import get_global_engine
from app.middleware.auth import get_current_user
from app.schemas.analysis_type import AnalysisTypeResponse
from app.services.config_service import AnalysisTypeService

router = APIRouter(prefix="/catalog", tags=["catalog"])


@router.get("/analysis-types", response_model=list[AnalysisTypeResponse])
def list_analysis_types(payload: dict = Depends(get_current_user)):
    engine = get_global_engine()
    with Session(engine) as session:
        svc = AnalysisTypeService(session)
        return [AnalysisTypeResponse(**t.model_dump()) for t in svc.list_all()]
