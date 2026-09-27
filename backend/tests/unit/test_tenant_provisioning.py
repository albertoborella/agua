"""Regression tests for lazy tenant provisioning and the unprovisioned-tenant error.

Background: a login for a tenant id that had never been seeded raised
`OperationalError: no such table: users` and surfaced as a CORS failure,
because the unhandled error escaped to Starlette's ServerErrorMiddleware,
which sits outside CORSMiddleware. Two behaviours are pinned here:

  1. `get_tenant_engine` provisions the schema on first use, idempotently.
  2. A tenant with a schema but no users gets a clear 404, not a 500, and the
     response still carries CORS headers.

DATABASE_DIR isolation: every test points `settings.DATABASE_DIR` at pytest's
`tmp_path` and clears the module-level engine cache. The live volume
(`/app/data/tenants` in the container) holds real seeded data and must never be
touched by a test run.
"""

import sqlite3

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, select

from app import database as database_module
from app.config import settings
from app.database import get_tenant_engine, init_tenant_db
from app.main import app
from app.models.user import User
from app.services.auth_service import hash_password

# The three users `scripts/seed_demo.py` creates for the demo tenant.
DEMO_USERS = [
    ("admin", "admin@demo.com", "Admin123!", "ADMIN"),
    ("operario", "operario@demo.com", "Operario123!", "OPERARIO"),
    ("lab", "lab@demo.com", "Lab123!", "LABORATORISTA"),
]

# One of the eight tables `demo/agua.db` carries in the live volume. Asserting
# on the real set keeps the fixture honest if a model is ever added or renamed.
EXPECTED_TABLES = {
    "alerts",
    "analysis_types",
    "plants",
    "sample_records",
    "sampling_frequencies",
    "tenants",
    "users",
    "water_sources",
}

ORIGIN = "http://localhost:8080"  # an origin in the default CORS allowlist


def table_names(db_path) -> set[str]:
    with sqlite3.connect(db_path) as raw:
        return {
            row[0]
            for row in raw.execute(
                "select name from sqlite_master where type='table'"
            )
        }


def seed_users(tenant_id: str, users=DEMO_USERS) -> None:
    """Insert users into an already-provisioned tenant, as seed_demo does."""
    with Session(get_tenant_engine(tenant_id)) as session:
        for username, email, password, rol in users:
            session.add(
                User(
                    tenant_id=tenant_id,
                    username=username,
                    email=email,
                    password_hash=hash_password(password),
                    rol=rol,
                )
            )
        session.commit()


def login(client: TestClient, tenant_id: str, username: str, password: str, **kwargs):
    return client.post(
        "/auth/login",
        data={
            "username": username,
            "password": password,
            "client_id": tenant_id,
        },
        **kwargs,
    )


@pytest.fixture
def tenant_dir(tmp_path, monkeypatch):
    """Redirect DATABASE_DIR at a throwaway directory for the duration of one test.

    `app.database` holds a reference to the same singleton `settings` object, so
    patching the attribute here is what `get_tenant_engine` reads. `_engines` is
    a process-level cache, so it is cleared on the way in and on the way out:
    clearing on entry gives the test a genuinely unseen tenant, and clearing on
    exit stops a tmp_path engine from leaking into the next test.
    """
    monkeypatch.setattr(settings, "DATABASE_DIR", str(tmp_path))
    database_module._engines.clear()
    yield tmp_path
    database_module._engines.clear()


# ── 1. a previously unseen tenant gets a usable schema ──────────────────────


def test_get_tenant_engine_provisions_schema_for_unseen_tenant(tenant_dir):
    engine = get_tenant_engine("nuevo")

    db_path = tenant_dir / "nuevo" / "agua.db"
    assert db_path.exists()
    assert "users" in table_names(db_path)

    # The regression itself: this query raised `no such table: users` before.
    with Session(engine) as session:
        assert session.exec(select(User).where(User.tenant_id == "nuevo")).first() is None


# ── 2. re-running is idempotent and never wipes data ───────────────────────


def test_second_resolution_is_cached_and_does_not_reprovision(tenant_dir):
    engine = get_tenant_engine("nuevo")
    seed_users("nuevo", [DEMO_USERS[0]])

    # Cache hit: the same engine comes back, so create_all is not re-run at all.
    assert get_tenant_engine("nuevo") is engine

    # The explicit entry point used by the seed scripts still works, and is a
    # no-op on an existing schema.
    init_tenant_db("nuevo")

    with Session(engine) as session:
        assert session.exec(select(User).where(User.username == "admin")).first() is not None


def test_create_all_on_a_populated_tenant_preserves_rows(tenant_dir):
    """The property the whole fix leans on: create_all never drops data.

    The engine cache is dropped between the two resolutions so that the second
    `get_tenant_engine` takes the full provision path against a tenant that
    already has rows — the case a seeded tenant is in after a restart.
    """
    engine = get_tenant_engine("demo")
    seed_users("demo")

    database_module._engines.clear()
    reprovisioned = get_tenant_engine("demo")
    init_tenant_db("demo")

    assert table_names(tenant_dir / "demo" / "agua.db") == EXPECTED_TABLES
    with Session(reprovisioned) as session:
        users = session.exec(select(User).where(User.tenant_id == "demo")).all()
    assert sorted(user.username for user in users) == ["admin", "lab", "operario"]


# ── 3. a tenant with no users gets a clear, CORS-bearing error ──────────────


def test_login_for_unprovisioned_tenant_returns_404_not_500(tenant_dir):
    response = login(
        TestClient(app), "memo", "admin", "Admin123!", headers={"Origin": ORIGIN}
    )

    assert response.status_code == 404, response.text
    detail = response.json()["detail"]
    assert "ID de empresa" in detail
    # The old message pointed at the password, which is not what was wrong.
    assert "Credenciales inválidas" not in detail

    # Handled inside the router, so it came back out through CORSMiddleware.
    # An unhandled 500 would have had no Access-Control-Allow-Origin at all.
    assert response.headers["access-control-allow-origin"] == ORIGIN


def test_login_for_unprovisioned_tenant_creates_its_schema(tenant_dir):
    """The 404 is only reachable because provisioning ran first."""
    login(TestClient(app), "memo", "admin", "Admin123!")

    assert "users" in table_names(tenant_dir / "memo" / "agua.db")


# ── 4. an existing tenant with a wrong password keeps the 401 ───────────────


def test_login_wrong_password_still_returns_401(tenant_dir):
    seed_users("demo")

    response = login(TestClient(app), "demo", "operario", "ContraseñaIncorrecta1")

    assert response.status_code == 401
    assert response.json()["detail"] == "Credenciales inválidas"
    assert response.headers["www-authenticate"] == "Bearer"


def test_login_unknown_username_on_existing_tenant_still_returns_401(tenant_dir):
    """The 404 keys off "tenant has no users", not "username was not found"."""
    seed_users("demo")

    response = login(TestClient(app), "demo", "fantasma", "Operario123!")

    assert response.status_code == 401
    assert response.json()["detail"] == "Credenciales inválidas"


# ── 5. the working demo tenant path is unchanged ────────────────────────────


def test_demo_tenant_login_succeeds(tenant_dir):
    init_tenant_db("demo")
    seed_users("demo")

    response = login(TestClient(app), "demo", "operario", "Operario123!")

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["access_token"] and body["refresh_token"]


def test_demo_tenant_keeps_all_eight_tables(tenant_dir):
    init_tenant_db("demo")

    assert table_names(tenant_dir / "demo" / "agua.db") == EXPECTED_TABLES


def test_missing_tenant_id_still_returns_400(tenant_dir):
    """Pins the pre-existing 400 that the new 404 must not swallow."""
    response = login(TestClient(app), "", "operario", "Operario123!")

    assert response.status_code == 400
    assert response.json()["detail"] == "Se requiere tenant_id (client_id)"
