from collections.abc import Generator
from pathlib import Path

from sqlmodel import Session, SQLModel, create_engine

from app.config import settings

_engines: dict[str, any] = {}


def _ensure_models_registered():
    import app.models  # noqa: F401 — triggers registration of all models


def get_tenant_engine(tenant_id: str):
    if tenant_id in _engines:
        return _engines[tenant_id]

    tenant_dir = Path(settings.DATABASE_DIR) / tenant_id
    tenant_dir.mkdir(parents=True, exist_ok=True)

    db_path = tenant_dir / "agua.db"
    url = f"sqlite:///{db_path}"
    engine = create_engine(url, echo=False)
    _engines[tenant_id] = engine
    return engine


def init_tenant_db(tenant_id: str) -> None:
    _ensure_models_registered()
    engine = get_tenant_engine(tenant_id)
    SQLModel.metadata.create_all(engine)


def get_db(tenant_id: str) -> Generator[Session, None, None]:
    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        yield session


def get_global_engine():
    if "_global" in _engines:
        return _engines["_global"]

    global_dir = Path(settings.DATABASE_DIR) / "_global"
    global_dir.mkdir(parents=True, exist_ok=True)

    db_path = global_dir / "global.db"
    url = f"sqlite:///{db_path}"
    engine = create_engine(url, echo=False)
    _engines["_global"] = engine
    return engine


def init_global_db() -> None:
    _ensure_models_registered()
    engine = get_global_engine()
    SQLModel.metadata.create_all(engine)


def get_global_db() -> Generator[Session, None, None]:
    engine = get_global_engine()
    with Session(engine) as session:
        yield session
