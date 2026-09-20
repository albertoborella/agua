from sqlmodel import Session, select

from app.models.alert import Alert
from app.repositories.base import BaseRepository


class AlertService:
    def __init__(self, session: Session):
        self.repo = BaseRepository(Alert, session)
        self.session = session

    def get_pending(self, tenant_id: str):
        return self.session.exec(
            select(Alert).where(
                Alert.tenant_id == tenant_id,
                Alert.leida == False,
            )
        ).all()

    def mark_read(self, tenant_id: str, alert_id: str) -> Alert | None:
        alert = self.session.exec(
            select(Alert).where(
                Alert.id == alert_id,
                Alert.tenant_id == tenant_id,
            )
        ).first()
        if not alert:
            return None
        alert.leida = True
        self.session.add(alert)
        self.session.commit()
        self.session.refresh(alert)
        return alert
