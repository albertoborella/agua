from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from app.database import get_tenant_engine
from app.middleware.auth import get_current_user
from app.schemas.alert import AlertResponse
from app.services.alert_service import AlertService

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.get("/pending", response_model=list[AlertResponse])
def get_pending_alerts(
    payload: dict = Depends(get_current_user),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = AlertService(session)
        alerts = svc.get_pending(tenant_id)
        return [AlertResponse(**a.model_dump()) for a in alerts]


@router.put("/{alert_id}/read", response_model=AlertResponse)
def mark_alert_read(
    alert_id: str,
    payload: dict = Depends(get_current_user),
):
    tenant_id = payload["tenant"]
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        svc = AlertService(session)
        alert = svc.mark_read(tenant_id, alert_id)
        if not alert:
            raise HTTPException(status_code=404, detail="Alerta no encontrada")
        return AlertResponse(**alert.model_dump())
