"""Integration tests for user management API endpoints."""

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine
from app.main import app
from app.database import get_tenant_engine, init_global_db, init_tenant_db
from app.models import UserRole, User, AnalysisType
from app.services.auth_service import create_access_token, hash_password
from app.repositories.base import BaseRepository


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def admin_token():
    """Create a valid admin token for tenant 'demo'."""
    return create_access_token({"sub": "admin-user-id", "tenant": "demo", "rol": "ADMIN"})


@pytest.fixture
def operario_token():
    """Create a valid operario token for tenant 'demo'."""
    return create_access_token({"sub": "operario-user-id", "tenant": "demo", "rol": "OPERARIO"})


@pytest.fixture(autouse=True)
def setup_tenant_db():
    """Setup test tenant database."""
    # Use a separate test tenant
    test_tenant = "test_tenant_roles"
    init_global_db()
    init_tenant_db(test_tenant)
    engine = get_tenant_engine(test_tenant)
    SQLModel.metadata.create_all(engine)
    
    # Create admin user
    with Session(engine) as session:
        user_repo = BaseRepository(User, session)
        user_repo.create({
            "id": "admin-user-id",
            "tenant_id": test_tenant,
            "username": "admin",
            "email": "admin@demo.com",
            "password_hash": hash_password("Admin123!"),
            "rol": "ADMIN",
            "activo": True,
        })
        user_repo.create({
            "id": "operario-user-id",
            "tenant_id": test_tenant,
            "username": "operario",
            "email": "operario@demo.com",
            "password_hash": hash_password("Operario123!"),
            "rol": "OPERARIO",
            "activo": True,
        })
    
    yield test_tenant
    
    # Cleanup
    import os
    db_path = f"./data/tenants/{test_tenant}/agua.db"
    if os.path.exists(db_path):
        os.remove(db_path)
    os.rmdir(f"./data/tenants/{test_tenant}")


class TestUserEndpoints:
    """Integration tests for /admin/users endpoints."""

    def test_list_users_as_admin(self, client, admin_token, setup_tenant_db):
        response = client.get(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == 200
        users = response.json()
        assert len(users) == 2
        usernames = {u["username"] for u in users}
        assert usernames == {"admin", "operario"}

    def test_list_users_as_operario_forbidden(self, client, operario_token, setup_tenant_db):
        response = client.get(
            "/admin/users",
            headers={"Authorization": f"Bearer {operario_token}"},
        )
        assert response.status_code == 403

    def test_create_user_valid_roles(self, client, admin_token, setup_tenant_db):
        for rol in ["ADMIN", "OPERARIO", "LABORATORISTA"]:
            response = client.post(
                "/admin/users",
                headers={"Authorization": f"Bearer {admin_token}"},
                json={
                    "username": f"new_{rol.lower()}",
                    "email": f"{rol.lower()}@demo.com",
                    "password": "NewPass123!",
                    "rol": rol,
                },
            )
            assert response.status_code == 200, f"Failed for role {rol}: {response.text}"
            data = response.json()
            assert data["rol"] == rol
            assert data["activo"] is True

    def test_create_user_invalid_role(self, client, admin_token, setup_tenant_db):
        response = client.post(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "username": "invalid_role",
                "email": "invalid@demo.com",
                "password": "NewPass123!",
                "rol": "INVALIDO",
            },
        )
        assert response.status_code == 422
        assert "Rol inválido" in response.text

    def test_create_user_duplicate_username(self, client, admin_token, setup_tenant_db):
        # Create first
        client.post(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "username": "duplicate",
                "email": "dup1@demo.com",
                "password": "Pass123!",
                "rol": "OPERARIO",
            },
        )
        # Try duplicate
        response = client.post(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "username": "duplicate",
                "email": "dup2@demo.com",
                "password": "Pass123!",
                "rol": "OPERARIO",
            },
        )
        assert response.status_code in (400, 409, 500)  # depends on DB constraint handling

    def test_update_user_role(self, client, admin_token, setup_tenant_db):
        # Create user
        create_resp = client.post(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "username": "toupdate",
                "email": "toupdate@demo.com",
                "password": "Pass123!",
                "rol": "OPERARIO",
            },
        )
        user_id = create_resp.json()["id"]

        # Update role
        response = client.put(
            f"/admin/users/{user_id}",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={"rol": "ADMIN"},
        )
        assert response.status_code == 200
        assert response.json()["rol"] == "ADMIN"

    def test_update_user_invalid_role(self, client, admin_token, setup_tenant_db):
        create_resp = client.post(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "username": "toupdate2",
                "email": "toupdate2@demo.com",
                "password": "Pass123!",
                "rol": "OPERARIO",
            },
        )
        user_id = create_resp.json()["id"]

        response = client.put(
            f"/admin/users/{user_id}",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={"rol": "INVALIDO"},
        )
        assert response.status_code == 422
        assert "Rol inválido" in response.text

    def test_update_user_activo(self, client, admin_token, setup_tenant_db):
        create_resp = client.post(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "username": "todeactivate",
                "email": "todeactivate@demo.com",
                "password": "Pass123!",
                "rol": "OPERARIO",
            },
        )
        user_id = create_resp.json()["id"]

        response = client.put(
            f"/admin/users/{user_id}",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={"activo": False},
        )
        assert response.status_code == 200
        assert response.json()["activo"] is False

    def test_reset_password(self, client, admin_token, setup_tenant_db):
        create_resp = client.post(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "username": "toreset",
                "email": "toreset@demo.com",
                "password": "OldPass123!",
                "rol": "OPERARIO",
            },
        )
        user_id = create_resp.json()["id"]

        response = client.post(
            f"/admin/users/{user_id}/reset-password",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={"new_password": "NewPass456!"},
        )
        assert response.status_code == 200
        assert "restablecida" in response.json()["message"]

    def test_delete_user(self, client, admin_token, setup_tenant_db):
        create_resp = client.post(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "username": "todelete",
                "email": "todelete@demo.com",
                "password": "Pass123!",
                "rol": "OPERARIO",
            },
        )
        user_id = create_resp.json()["id"]

        response = client.delete(
            f"/admin/users/{user_id}",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == 200
        assert "eliminado" in response.json()["message"]

        # Verify deleted
        list_resp = client.get(
            "/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        usernames = {u["username"] for u in list_resp.json()}
        assert "todelete" not in usernames

    def test_delete_nonexistent_user(self, client, admin_token, setup_tenant_db):
        response = client.delete(
            "/admin/users/nonexistent-id",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == 404