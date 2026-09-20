import uuid
from datetime import datetime, timezone
from typing import Any, Generic, Sequence, TypeVar

from sqlmodel import Session, SQLModel, select

ModelT = TypeVar("ModelT", bound=SQLModel)


class BaseRepository(Generic[ModelT]):
    def __init__(self, model: type[ModelT], session: Session):
        self.model = model
        self.session = session

    def get(self, id: str) -> ModelT | None:
        return self.session.get(self.model, id)

    def get_by_tenant(self, tenant_id: str, id: str) -> ModelT | None:
        return self.session.exec(
            select(self.model).where(
                self.model.id == id, self.model.tenant_id == tenant_id
            )
        ).first()

    def list_by_tenant(self, tenant_id: str, skip: int = 0, limit: int = 100) -> Sequence[ModelT]:
        return self.session.exec(
            select(self.model)
            .where(self.model.tenant_id == tenant_id)
            .offset(skip)
            .limit(limit)
        ).all()

    def create(self, data: dict[str, Any]) -> ModelT:
        data.setdefault("id", str(uuid.uuid4()))
        data.setdefault("created_at", datetime.now(timezone.utc).isoformat())
        obj = self.model(**data)
        self.session.add(obj)
        self.session.commit()
        self.session.refresh(obj)
        return obj

    def update(self, id: str, data: dict[str, Any]) -> ModelT | None:
        obj = self.session.get(self.model, id)
        if not obj:
            return None
        for key, value in data.items():
            if value is not None:
                setattr(obj, key, value)
        self.session.add(obj)
        self.session.commit()
        self.session.refresh(obj)
        return obj

    def delete(self, id: str) -> bool:
        obj = self.session.get(self.model, id)
        if not obj:
            return False
        self.session.delete(obj)
        self.session.commit()
        return True
