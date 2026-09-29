"""Tests for UserRole enum validation."""

import pytest
from app.models.role import UserRole
from app.schemas.user import UserCreate, UserUpdate
from app.services.user_service import UserService
from sqlmodel import Session, SQLModel, create_engine
from app.models.user import User
from app.services.auth_service import hash_password


class TestUserRoleEnum:
    """Tests for UserRole enum."""

    def test_values(self):
        assert UserRole.values() == ["ADMIN", "OPERARIO", "LABORATORISTA"]

    def test_is_valid_true(self):
        assert UserRole.is_valid("ADMIN") is True
        assert UserRole.is_valid("OPERARIO") is True
        assert UserRole.is_valid("LABORATORISTA") is True

    def test_is_valid_false(self):
        assert UserRole.is_valid("INVALIDO") is False
        assert UserRole.is_valid("admin") is False  # case sensitive
        assert UserRole.is_valid("") is False
        assert UserRole.is_valid(None) is False  # type: ignore


class TestUserSchemasValidation:
    """Tests for Pydantic schema validation."""

    def test_user_create_valid_roles(self):
        for rol in ["ADMIN", "OPERARIO", "LABORATORISTA"]:
            user = UserCreate(username="test", email="test@test.com", password="12345678", rol=rol)
            assert user.rol == rol

    def test_user_create_invalid_role(self):
        with pytest.raises(ValueError, match="Rol inválido"):
            UserCreate(username="test", email="test@test.com", password="12345678", rol="INVALIDO")

    def test_user_update_valid_roles(self):
        for rol in ["ADMIN", "OPERARIO", "LABORATORISTA"]:
            user = UserUpdate(rol=rol)
            assert user.rol == rol

    def test_user_update_none_rol(self):
        user = UserUpdate(rol=None)
        assert user.rol is None

    def test_user_update_invalid_role(self):
        with pytest.raises(ValueError, match="Rol inválido"):
            UserUpdate(rol="INVALIDO")


class TestUserServiceValidation:
    """Tests for UserService validation."""

    @pytest.fixture
    def session(self):
        engine = create_engine("sqlite:///:memory:")
        SQLModel.metadata.create_all(engine)
        with Session(engine) as session:
            yield session

    def test_create_user_valid_roles(self, session):
        svc = UserService(session)
        for rol in ["ADMIN", "OPERARIO", "LABORATORISTA"]:
            user = svc.create_user("demo", f"user_{rol.lower()}", f"{rol.lower()}@demo.com", "Pass123!", rol)
            assert user.rol == rol

    def test_create_user_invalid_role(self, session):
        svc = UserService(session)
        with pytest.raises(ValueError, match="Rol inválido"):
            svc.create_user("demo", "invalid", "invalid@demo.com", "Pass123!", "INVALIDO")

    def test_update_user_valid_role(self, session):
        svc = UserService(session)
        user = svc.create_user("demo", "testuser", "test@demo.com", "Pass123!", "OPERARIO")
        updated = svc.update_user("demo", user.id, rol="ADMIN")
        assert updated.rol == "ADMIN"

    def test_update_user_invalid_role(self, session):
        svc = UserService(session)
        user = svc.create_user("demo", "testuser", "test@demo.com", "Pass123!", "OPERARIO")
        with pytest.raises(ValueError, match="Rol inválido"):
            svc.update_user("demo", user.id, rol="INVALIDO")

    def test_update_user_none_rol_ignored(self, session):
        svc = UserService(session)
        user = svc.create_user("demo", "testuser", "test@demo.com", "Pass123!", "OPERARIO")
        updated = svc.update_user("demo", user.id, email="new@demo.com")
        assert updated.rol == "OPERARIO"  # unchanged
        assert updated.email == "new@demo.com"

    def test_create_user_password_hashed(self, session):
        svc = UserService(session)
        user = svc.create_user("demo", "testpass", "testpass@demo.com", "MiPass123!", "OPERARIO")
        assert user.password_hash != "MiPass123!"
        assert len(user.password_hash) > 20

    def test_reset_password_hashes_new_password(self, session):
        svc = UserService(session)
        user = svc.create_user("demo", "testpass2", "testpass2@demo.com", "OldPass123!", "OPERARIO")
        old_hash = user.password_hash
        updated = svc.reset_password("demo", user.id, "NewPass456!")
        assert updated.password_hash != old_hash
        assert updated.password_hash != "NewPass456!"