#!/usr/bin/env python3
"""CLI script to create the first superadmin for a tenant."""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlmodel import Session

from app.database import get_tenant_engine, init_tenant_db
from app.models.tenant import Tenant
from app.services.auth_service import hash_password
from app.services.user_service import UserService


def create_superadmin(
    tenant_name: str,
    admin_username: str,
    admin_email: str,
    admin_password: str,
    tenant_id: str | None = None,
):
    import uuid

    if not tenant_id:
        tenant_id = str(uuid.uuid4())

    init_tenant_db(tenant_id)

    engine = get_tenant_engine(tenant_id)
    with Session(engine) as session:
        tenant = Tenant(id=tenant_id, nombre=tenant_name, activa=True)
        session.add(tenant)
        session.commit()
        session.refresh(tenant)

        svc = UserService(session)
        user = svc.create_user(
            tenant_id=tenant_id,
            username=admin_username,
            email=admin_email,
            password=admin_password,
            rol="ADMIN",
        )

        print(f"Tenant creado: {tenant_name} (ID: {tenant_id})")
        print(f"Admin creado: {admin_username} (ID: {user.id})")
        print(f"Base de datos: app/data/tenants/{tenant_id}/agua.db")

        return tenant_id, user.id


def main():
    parser = argparse.ArgumentParser(description="Crear superadmin para Agua")
    parser.add_argument("--tenant-name", required=True, help="Nombre del tenant")
    parser.add_argument("--tenant-id", default=None, help="UUID del tenant (auto-generado si no se provee)")
    parser.add_argument("--admin-username", required=True, help="Username del admin")
    parser.add_argument("--admin-email", required=True, help="Email del admin")
    parser.add_argument("--admin-password", required=True, help="Password del admin")
    args = parser.parse_args()

    create_superadmin(
        tenant_name=args.tenant_name,
        admin_username=args.admin_username,
        admin_email=args.admin_email,
        admin_password=args.admin_password,
        tenant_id=args.tenant_id,
    )


if __name__ == "__main__":
    main()
