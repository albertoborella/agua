"""Tenant id validation: a client-supplied id must never become a path segment.

`login()` takes the tenant from the OAuth2 `client_id` form field and passes it
to `get_tenant_engine`, which did:

    tenant_dir = Path(settings.DATABASE_DIR) / tenant_id

`pathlib` does not normalise, check or refuse, so `client_id=../..` resolved
outside the tenant directory and had a SQLite file created there. Since
82f01d7 the same call also runs `SQLModel.metadata.create_all` for a
newly-resolved tenant, so the escaped path received a full schema, not just an
empty file. The capability was pre-existing; that commit widened the blast
radius.

Two sites are covered, and they must agree:

  1. `login()` is the trust boundary — the value is still client-supplied, so
     it is refused there with a 400 in Spanish, before any filesystem call.
  2. `get_tenant_engine` is the chokepoint — the site that actually builds the
     path. The same tenant id also arrives from the signed JWT `tenant` claim
     on every authenticated request, so the path builder refuses it too.

Both call the same predicate, so an id that one accepts the other accepts.

`DATABASE_DIR` isolation: identical to `test_tenant_provisioning.py` — every
test points `settings.DATABASE_DIR` at a directory under pytest's `tmp_path`
and clears the module-level engine cache on the way in and out. One extra
twist: the base is nested (`tmp_path/vol/tenants`) so that a `../..` escape
lands back INSIDE `tmp_path` and can be observed, and every test asserts that
no path anywhere under `tmp_path` was created or changed. The live volume
(`/app/data/tenants`) must never be touched by a test run.
"""

import uuid

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session

from app import database as database_module
from app.config import settings
from app.database import get_global_engine, get_tenant_engine, init_tenant_db
from app.main import app
from app.models.user import User
from app.services.auth_service import create_access_token
from tests.unit.test_tenant_provisioning import (
    DEMO_USERS,
    EXPECTED_TABLES,
    login,
    seed_users,
    table_names,
)


def validator():
    """Return `(InvalidTenantId, validate_tenant_id)` from `app.database`.

    Imported inside the tests rather than at module scope on purpose. Against
    the unfixed code these two symbols do not exist, and a top-level import
    would abort collection for the whole file, reporting zero results. Lazy
    means every other test in this module still runs and reports its actual
    assertion failure, which is what a red run is for.
    """
    from app.database import InvalidTenantId, validate_tenant_id

    return InvalidTenantId, validate_tenant_id


# ── the ids the system actually uses, and the ones it must still accept ─────

# `demo` and `memo` are the seeded/known tenants, `_global` is the reserved
# key for `get_global_engine`, and a UUIDv4 string is what
# `scripts/createsuperadmin.py` generates when no `--tenant-id` is given.
# That last one is the case that forces `-` into the character set: a tenant id
# in this system is not necessarily a human-typed word.
VALID_IDS = [
    "demo",
    "memo",
    "_global",
    "nuevo",
    str(uuid.uuid4()),
    "Acme-Agua_2026",
    "a" * 64,  # exactly at the length bound
]

# Every shape that must be refused. Grouped by the trick being used, because
# the point of an allowlist is that it does not care which trick is tried.
TRAVERSAL_IDS = [
    pytest.param("..", id="dotdot"),
    pytest.param("../..", id="dotdot-escape-two-levels"),
    pytest.param("....//", id="dotdot-naive-denylist-bypass"),
    pytest.param("foo/../../bar", id="traversal-inside-a-valid-looking-id"),
    pytest.param("demo/../demo", id="traversal-that-resolves-back-inside"),
    pytest.param("demo/..", id="traversal-to-parent"),
    pytest.param("..%2f", id="trailing-percent-encoded-slash"),
    pytest.param("./..", id="dot-slash-dotdot"),
    pytest.param(".demo", id="leading-dot"),
    pytest.param(".", id="dot"),
    pytest.param("..\\..", id="backslash-traversal-windows"),
    pytest.param("foo\\..\\bar", id="backslash-inside"),
    # A denylist of `..` and of a leading dot would let all three of these
    # through. The allowlist does not, which is the whole argument for it.
    pytest.param("demo..memo", id="embedded-dotdot"),
    pytest.param("demo.db", id="extension-looking"),
    pytest.param("demo\nrm -rf /", id="newline-log-injection"),
    pytest.param("demo\x1b[31m", id="ansi-escape"),
    pytest.param(" demo", id="leading-space"),
    pytest.param("demo ", id="trailing-space"),
    pytest.param("démo", id="non-ascii-letter"),
    pytest.param("%2e%2e%2f", id="percent-encoded-traversal"),
    pytest.param("demo%00", id="literal-percent-encoded-nul"),
    pytest.param("a" * 65, id="one-over-the-length-bound"),
    pytest.param("a" * 4096, id="far-over-the-length-bound"),
    pytest.param("de\x00mo", id="nul-byte"),
    pytest.param("a\x00b", id="nul-byte-between-valid-chars"),
]

# Same list, as plain strings, for the tests that only need to iterate it.
MALFORMED_IDS = [p.values[0] for p in TRAVERSAL_IDS]


# ── isolation ───────────────────────────────────────────────────────────────


@pytest.fixture
def tenant_root(tmp_path, monkeypatch):
    """Redirect DATABASE_DIR at a throwaway tree and hand back the sandbox root.

    The base is `tmp_path/vol/tenants` rather than `tmp_path` itself so that a
    `../..` escape resolves back to `tmp_path`, which is a directory this test
    is allowed to inspect. If the base were `tmp_path` the same escape would
    land in pytest's own per-test root's parent, where an assertion could not
    see it and where writing would be rude.

    `app.database` holds a reference to the same singleton `settings` object,
    so patching the attribute here is what `get_tenant_engine` reads. `_engines`
    is a process-level cache: cleared on the way in so each test starts from a
    genuinely unseen tenant, and on the way out so a tmp_path engine does not
    leak into the next test.
    """
    data_dir = tmp_path / "vol" / "tenants"
    data_dir.mkdir(parents=True)
    monkeypatch.setattr(settings, "DATABASE_DIR", str(data_dir))
    database_module._engines.clear()
    yield tmp_path
    database_module._engines.clear()


@pytest.fixture
def client():
    # `raise_server_exceptions=False` so a defence-in-depth refusal surfaces
    # as a 500 response instead of an exception out of the test. The JWT-claim
    # test below relies on it to observe the fail-closed status.
    return TestClient(app, raise_server_exceptions=False)


def snapshot(root) -> set[str]:
    """Every path under `root`, relative to it, as a set of strings."""
    return {str(p.relative_to(root)) for p in root.rglob("*")}


# ── 1. the trust boundary: a traversal client_id is a 400, and writes nothing ──


def test_login_with_dotdot_dotdot_is_400_and_escapes_nothing(tenant_root, client):
    """The reported vulnerability, asserted as a filesystem fact.

    Asserting only the status code would pass even if the directory had
    already been created before the rejection. So: a sentinel that must be
    byte-identical afterwards, and a full before/after diff of the whole
    sandbox tree, which catches an escape to any depth, not just to the
    two-levels-up this particular payload targets.
    """
    sentinel = tenant_root / "sentinel"
    sentinel.mkdir()
    (sentinel / "keep.txt").write_text("intacto")

    before = snapshot(tenant_root)

    response = login(client, "../..", "admin", "Admin123!")

    assert response.status_code == 400, response.text

    # Nothing new anywhere in the sandbox. `../..` from `vol/tenants` is the
    # sandbox root, so an escape would land on `tenant_root/agua.db`.
    assert snapshot(tenant_root) - before == set()

    # ...and said twice, concretely, so the failure message names the artefact.
    assert not (tenant_root / "agua.db").exists()
    assert [p.name for p in sentinel.iterdir()] == ["keep.txt"]
    assert (sentinel / "keep.txt").read_text() == "intacto"

    # The valid-database subdirectory was not touched either.
    assert (tenant_root / "vol" / "tenants").is_dir()
    assert list((tenant_root / "vol" / "tenants").iterdir()) == []


@pytest.mark.parametrize("tenant_id", TRAVERSAL_IDS)
def test_login_rejects_malformed_tenant_id(tenant_root, client, tenant_id):
    sentinel = tenant_root / "sentinel"
    sentinel.mkdir()
    (sentinel / "keep.txt").write_text("intacto")
    before = snapshot(tenant_root)

    response = login(client, tenant_id, "admin", "Admin123!")

    assert response.status_code == 400, (
        f"client_id={tenant_id!r} devolvió {response.status_code}, se esperaba 400"
    )
    assert snapshot(tenant_root) - before == set()
    assert [p.name for p in sentinel.iterdir()] == ["keep.txt"]


def test_login_rejects_an_absolute_path(tenant_root, client):
    """An absolute `client_id` wins the `Path(base) / value` join outright.

    The payload is built from `tmp_path` rather than a real `/tmp/evil` on
    purpose: pre-fix, this test actually creates the directory, and the point
    of the run is that no test may write outside its sandbox even while
    failing. The code path exercised is identical — pathlib discards the base
    when the right-hand side is absolute.
    """
    outside = tenant_root / "abs_escape"
    before = snapshot(tenant_root)

    response = login(client, str(outside), "admin", "Admin123!")

    assert response.status_code == 400, response.text
    assert not outside.exists()
    assert snapshot(tenant_root) - before == set()


def test_the_400_never_echoes_a_control_character_back(tenant_root, client):
    """The rejected value comes from a form field and lands in a JSON body.

    Echoing it raw would let a caller inject newlines or ANSI escapes into
    whatever logs the detail, and into the Flutter error surface. `repr`
    renders them as the literal text `\\x00` / `\\n`, so the message stays
    readable for the person who mistyped a real id.
    """
    response = login(client, "de\x00mo", "admin", "Admin123!")

    assert response.status_code == 400
    detail = response.json()["detail"]
    assert "\x00" not in detail
    assert "de\\x00mo" in detail  # escaped, not stripped: still diagnosable

    # And the whole raw body carries no control character either.
    assert not any(ord(c) < 0x20 and c not in "\r\n\t" for c in response.text)


def test_the_400_explains_the_rule_in_spanish(tenant_root, client):
    response = login(client, "../..", "admin", "Admin123!")

    assert response.status_code == 400
    detail = response.json()["detail"]
    assert "ID de empresa" in detail
    # The message states the rule, not just "bad input": the caller picked
    # this value and needs to know what a legal one looks like.
    assert "guion bajo" in detail


# ── 2. the chokepoint: the path builder refuses on its own ──────────────────


@pytest.mark.parametrize("tenant_id", [p.values[0] for p in TRAVERSAL_IDS])
def test_get_tenant_engine_refuses_malformed_tenant_id(tenant_root, tenant_id):
    """`get_tenant_engine` is the thing that builds the path, so it refuses.

    Reached in production from every authenticated route, via the JWT `tenant`
    claim. That claim is signed, so it is not attacker-controlled under a sound
    `JWT_SECRET` — this is defence in depth at the construction site, not a
    claim that the claim is forgeable.
    """
    from app.database import InvalidTenantId

    before = snapshot(tenant_root)

    with pytest.raises(InvalidTenantId):
        get_tenant_engine(tenant_id)

    assert snapshot(tenant_root) - before == set()


def test_get_tenant_engine_refuses_an_empty_tenant_id(tenant_root):
    from app.database import InvalidTenantId

    with pytest.raises(InvalidTenantId):
        get_tenant_engine("")


def test_init_tenant_db_refuses_malformed_tenant_id(tenant_root):
    """The seed-script entry point goes through the same chokepoint."""
    from app.database import InvalidTenantId

    before = snapshot(tenant_root)

    with pytest.raises(InvalidTenantId):
        init_tenant_db("../../escaped")

    assert snapshot(tenant_root) - before == set()


def test_signed_token_with_a_traversal_tenant_fails_closed(tenant_root, client):
    """The JWT path, end to end: a valid signature carrying `tenant: "../.."`.

    Minted here with the real signing key, so `decode_token` accepts it — the
    point is that the signature being sound is not what stops the traversal.
    The chokepoint does.

    The route answers 500: `get_current_user` does not validate the claim, and
    `InvalidTenantId` is not an `HTTPException`, so it escapes to
    ServerErrorMiddleware. That is fail-closed, and it is only reachable by a
    token minted before this fix — a token cannot carry a traversal tenant
    today, because `login` now refuses to mint one.
    """
    token = create_access_token({"sub": "u-1", "tenant": "../..", "rol": "ADMIN"})

    before = snapshot(tenant_root)
    response = client.get(
        "/admin/plants", headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code >= 400
    assert snapshot(tenant_root) - before == set()
    assert not (tenant_root / "agua.db").exists()


# ── 3. the regression guard: the ids in use keep working ────────────────────


@pytest.mark.parametrize("tenant_id", ["demo", "memo", "_global"])
def test_ids_in_use_still_resolve_and_get_their_schema(tenant_root, tenant_id):
    """The test most likely to fail if the character set is too tight.

    `_global` is the awkward one: it is both a key in `_engines` and a
    directory name (`_global/global.db`), and it leads with an underscore.
    A "must start alphanumeric" rule would reject it.
    """
    engine = get_tenant_engine(tenant_id)

    db_path = tenant_root / "vol" / "tenants" / tenant_id / "agua.db"
    assert db_path.exists()
    assert table_names(db_path) == EXPECTED_TABLES

    with Session(engine) as session:
        assert session.query(User).count() == 0


def test_global_database_still_resolves(tenant_root):
    """`get_global_engine` builds its own path and is NOT routed through
    `get_tenant_engine`, so it is checked separately: `_global/global.db`,
    not `_global/agua.db`."""
    get_global_engine()

    global_db = tenant_root / "vol" / "tenants" / "_global" / "global.db"
    assert global_db.exists()
    assert table_names(global_db) == EXPECTED_TABLES
    assert not (tenant_root / "vol" / "tenants" / "_global" / "agua.db").exists()


def test_global_and_tenant_paths_do_not_share_an_engine(tenant_root):
    """`_engines` is keyed by tenant id, and `get_global_engine` uses the
    reserved id `_global`. Resolving the tenant `_global` and the global
    database in the same process therefore collide on one cache key, and
    whichever ran second is handed the other's file. Pre-existing; pinned so
    the fix does not quietly turn it into something worse."""
    tenant_engine = get_tenant_engine("_global")
    database_module._engines.clear()
    global_engine = get_global_engine()

    assert str(tenant_engine.url) != str(global_engine.url)


@pytest.mark.parametrize("tenant_id", VALID_IDS)
def test_valid_ids_are_accepted(tenant_root, tenant_id):
    assert validate_tenant_id(tenant_id) == tenant_id


def test_demo_tenant_login_still_succeeds(tenant_root, client):
    """The end-to-end path that matters in production, unchanged."""
    init_tenant_db("demo")
    seed_users("demo")

    response = login(client, "demo", "operario", "Operario123!")

    assert response.status_code == 200, response.text
    assert response.json()["access_token"]


def test_seeded_data_survives_reprovisioning(tenant_root):
    """`create_all` on a populated tenant must not touch a row — the property
    the provisioning call leans on, re-checked here so the added validation
    did not change the resolution order."""
    init_tenant_db("demo")
    seed_users("demo")
    database_module._engines.clear()
    init_tenant_db("demo")

    with Session(get_tenant_engine("demo")) as session:
        users = session.query(User).all()
    assert sorted(u.username for u in users) == ["admin", "lab", "operario"]


# ── 4. 400 vs 404: malformed is not the same as unregistered ────────────────


def test_well_formed_but_unregistered_tenant_is_404_not_400(tenant_root, client):
    """`memo` is a legal id that simply has no users. That is a 404 with the
    message from 82f01d7, NOT a 400 — the two mean different things to whoever
    is typing, and to the client, whose renewal path watches for 401.

    A validator that rejected legal ids would swallow this into a 400 and the
    "your company id is not registered" message would become unreachable.
    """
    response = login(client, "memo", "admin", "Admin123!")

    assert response.status_code == 404, response.text
    detail = response.json()["detail"]
    assert "ID de empresa" in detail
    assert "no está registrado" in detail

    # It was still provisioned on the way in: the 404 depends on it.
    assert "users" in table_names(tenant_root / "vol" / "tenants" / "memo" / "agua.db")


def test_underscore_global_login_is_404_which_proves_it_was_accepted(tenant_root, client):
    """`_global` has no users, so login answers 404. A 400 here would mean the
    validator had started rejecting the reserved id."""
    response = login(client, "_global", "admin", "Admin123!")

    assert response.status_code == 404, response.text


def test_wrong_password_on_a_real_tenant_is_still_401(tenant_root, client):
    """Untouched by this work, and the reason the 404 above is keyed off
    "tenant has no users" rather than "auth failed"."""
    init_tenant_db("demo")
    seed_users("demo", DEMO_USERS[:1])

    response = login(client, "demo", "admin", "Admin123!")

    assert response.status_code == 401
    assert response.json()["detail"] == "Credenciales inválidas"


# ── 5. the two sites cannot drift apart ─────────────────────────────────────


@pytest.mark.parametrize("tenant_id", VALID_IDS + [p.values[0] for p in TRAVERSAL_IDS])
def test_router_and_chokepoint_agree_on_every_id(tenant_root, client, tenant_id):
    """The acceptance rule: one predicate, two call sites.

    If the router ever grew a laxer rule than the chokepoint (or vice versa)
    an id could be accepted at the boundary and then blow up at the path
    builder, or — worse — be refused at the boundary while a token-minted one
    sailed through. Asserted as an equivalence over the whole id corpus.
    """
    try:
        validate_tenant_id(tenant_id)
        boundary_accepts = True
    except Exception:
        boundary_accepts = False

    status = login(client, tenant_id, "admin", "Admin123!").status_code

    assert (status == 400) is not boundary_accepts, (
        f"{tenant_id!r}: login devolvió {status}, "
        f"validate_tenant_id aceptó={boundary_accepts}"
    )


# ── 6. /auth/refresh: the second place a client hands over a tenant ──────────


def test_refresh_refuses_to_reissue_a_token_with_a_traversal_tenant(tenant_root, client):
    """`refresh` does not touch the filesystem, but it re-mints the claims.

    Left open, a traversal tenant baked into a token before this fix renews
    itself every 7 days forever, and the 400 at `login` never gets a chance to
    matter. A token whose tenant is unusable is a token this backend will not
    honour: 401, so the client clears the session and logs in again.
    """
    token = create_access_token({"sub": "u-1", "tenant": "../..", "rol": "ADMIN"})

    before = snapshot(tenant_root)
    response = client.post("/auth/refresh", json={"refresh_token": token})

    assert response.status_code == 401, response.text
    assert snapshot(tenant_root) - before == set()


def test_refresh_still_works_for_a_real_tenant(tenant_root, client):
    init_tenant_db("demo")
    seed_users("demo")
    token = create_access_token({"sub": "u-1", "tenant": "demo", "rol": "OPERARIO"})

    response = client.post("/auth/refresh", json={"refresh_token": token})

    assert response.status_code == 200, response.text
    assert response.json()["access_token"]
