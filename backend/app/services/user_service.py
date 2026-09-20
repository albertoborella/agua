from sqlmodel import Session

from app.models.user import User
from app.repositories.base import BaseRepository
from app.services.auth_service import hash_password


class UserService:
    def __init__(self, session: Session):
        self.repo = BaseRepository(User, session)
        self.session = session

    def create_user(self, tenant_id: str, username: str, email: str, password: str, rol: str) -> User:
        return self.repo.create(
            {
                "tenant_id": tenant_id,
                "username": username,
                "email": email,
                "password_hash": hash_password(password),
                "rol": rol,
            }
        )

    def get_user(self, tenant_id: str, user_id: str) -> User | None:
        return self.repo.get_by_tenant(tenant_id, user_id)

    def list_users(self, tenant_id: str, skip: int = 0, limit: int = 100):
        return self.repo.list_by_tenant(tenant_id, skip, limit)

    def update_user(self, tenant_id: str, user_id: str, **kwargs) -> User | None:
        return self.repo.update(user_id, kwargs)

    def delete_user(self, tenant_id: str, user_id: str) -> bool:
        return self.repo.delete(user_id)

    def reset_password(self, tenant_id: str, user_id: str, new_password: str) -> User | None:
        return self.repo.update(user_id, {"password_hash": hash_password(new_password)})
