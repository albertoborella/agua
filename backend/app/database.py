import threading
from collections.abc import Generator
from pathlib import Path

from sqlalchemy.engine import Engine
from sqlmodel import Session, SQLModel, create_engine

from app.config import settings

_engines: dict[str, Engine] = {}

# Guards engine creation + schema provisioning below. FastAPI runs sync
# endpoints in a threadpool, so two requests for the same brand-new tenant can
# enter `get_tenant_engine` at the same time. The lock also makes the
# "create_all is safe to re-run" claim below actually true: see
# `_provision_tenant_schema` for why it is not safe on its own.
_engine_lock = threading.Lock()


def _ensure_models_registered():
    import app.models  # noqa: F401 — triggers registration of all models


def _provision_tenant_schema(engine: Engine) -> None:
    """Create any missing tables for a freshly resolved tenant.

    Two things have to be true before `create_all` is worth calling:
    the models are registered (otherwise the metadata is empty and it creates
    ZERO tables, silently), and the engine is already in `_engines` (otherwise
    `init_tenant_db` -> `get_tenant_engine` -> here would recurse forever).
    Callers below guarantee both.

    Re-running this on an already-seeded tenant is safe because `create_all`
    defaults to `checkfirst=True`: it reflects the existing database and emits
    DDL only for objects that are genuinely missing. Existing tables are left
    alone and no row is touched, so `demo` (8 tables, populated) is unaffected —
    this is the property that lets provisioning live on the request path
    instead of only in the seed scripts.
    """
    _ensure_models_registered()
    SQLModel.metadata.create_all(engine)


def get_tenant_engine(tenant_id: str) -> Engine:
    cached = _engines.get(tenant_id)
    if cached is not None:
        return cached

    with _engine_lock:
        # Re-check inside the lock: another thread may have resolved this
        # tenant while we waited for it. Without this both threads would build
        # an engine and both would provision.
        cached = _engines.get(tenant_id)
        if cached is not None:
            return cached

        tenant_dir = Path(settings.DATABASE_DIR) / tenant_id
        tenant_dir.mkdir(parents=True, exist_ok=True)

        db_path = tenant_dir / "agua.db"
        url = f"sqlite:///{db_path}"
        engine = create_engine(url, echo=False)

        # Cache BEFORE provisioning. `_provision_tenant_schema` does not call
        # back into `get_tenant_engine`, but caching first means that even if
        # that ever changes, this is a re-entrant cache hit and not a
        # deadlock or a fresh engine handed to `create_all`.
        _engines[tenant_id] = engine

        # A tenant directory is created on connect whether or not anyone ever
        # initialises it, so an unseen tenant id used to yield a 0-byte SQLite
        # file and the first query against it raised
        # `OperationalError: no such table: users`. Provision here, on first
        # resolution only — the cache hit above means this never runs again for
        # this tenant in this process, so it costs one `create_all` per tenant
        # per process, not one per request.
        _provision_tenant_schema(engine)
        return engine


def init_tenant_db(tenant_id: str) -> None:
    _ensure_models_registered()
    engine = get_tenant_engine(tenant_id)  # provisions on a cache miss
    # Still called explicitly: this function is the "make sure the schema
    # exists" entry point used by `scripts/seed_demo.py` and
    # `scripts/createsuperadmin.py`, and it has to hold when the engine is
    # already cached (a warm process, or seed_demo's reset path which drops
    # every table through a cached engine). `create_all` is a no-op when the
    # schema is already there.
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
