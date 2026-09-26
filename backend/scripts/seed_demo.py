#!/usr/bin/env python3
"""Seed the Agua backend with coherent demo data.

Creates a tenant with one plant, water sources, the global analysis-type
catalog, sampling frequencies, users for every role, sample history, and
alerts. The tenant id is fixed by default so demo credentials stay stable.

Usage (inside the container):
    python scripts/seed_demo.py --reset

Why this script bypasses the services in some places:
- `AnalysisType` has no `created_at` column, but `BaseRepository.create`
  injects one unconditionally, so the catalog is inserted directly.
- `SampleService.create_sample` hardcodes fecha/hora to `now`, so history is
  backdated through the repository, which honours an explicit `created_at`.
- Nothing in the backend ever creates alerts, so they are inserted here.
"""

import argparse
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlmodel import Session, select

from app.database import get_global_engine, get_tenant_engine, init_global_db, init_tenant_db
from app.models import (
    Alert,
    AnalysisType,
    Plant,
    SampleRecord,
    SamplingFrequency,
    WaterSource,
)
from app.repositories.base import BaseRepository
from app.services.user_service import UserService

TENANT_ID = "demo"
PLANT_ID = "plant-demo-001"

# Global catalog. `codigo` is what marks a type as chlorine — the model has no
# boolean flag, so the business rule keys off this exact string.
ANALYSIS_TYPES = [
    ("at-cloro", "CLORO", "Nivel de Cloro", False),
    ("at-fq", "FQ", "Analisis Fisicoquimico", False),
    ("at-mb", "MB", "Analisis Microbiologico", False),
    ("at-otro", "OTRO", "Otro Analisis", True),
]

USERS = [
    ("admin", "admin@demo.com", "Admin123!", "ADMIN"),
    ("operario", "operario@demo.com", "Operario123!", "OPERARIO"),
    ("lab", "lab@demo.com", "Lab123!", "LABORATORISTA"),
]

SOURCES = [
    ("ws-grifo-1", "GRIFO", "Grifo Cocina", "Planta baja - cocina"),
    ("ws-grifo-2", "GRIFO", "Grifo Limpieza", "Planta baja - deposito"),
    ("ws-grifo-3", "GRIFO", "Grifo Bebedero", "Planta alta - bebedero"),
    ("ws-pozo-1", "POZO", "Pozo Norte", "Sector norte"),
    ("ws-pozo-2", "POZO", "Pozo Sur", "Sector sur"),
]


def seed_analysis_types() -> None:
    """Insert the global catalog. Idempotent: skips codes that already exist."""
    init_global_db()
    with Session(get_global_engine()) as session:
        existing = {t.codigo for t in session.exec(select(AnalysisType)).all()}
        created = 0
        for type_id, codigo, nombre, requiere in ANALYSIS_TYPES:
            if codigo in existing:
                continue
            session.add(
                AnalysisType(
                    id=type_id,
                    codigo=codigo,
                    nombre=nombre,
                    requiere_descripcion=requiere,
                )
            )
            created += 1
        if created:
            session.commit()
        print(f"  analysis_types: {created} creados, {len(existing)} existentes")


def seed_tenant(tenant_id: str, reset: bool) -> str | None:
    engine_path = Path("./data/tenants") / tenant_id / "agua.db"
    if engine_path.exists() and reset:
        # Drop the tables instead of unlinking the file. Deleting it would
        # give the tenant a new inode, and a running uvicorn keeps serving the
        # unlinked copy — the API would report the old data with no error.
        from sqlmodel import SQLModel

        engine = get_tenant_engine(tenant_id)
        SQLModel.metadata.drop_all(engine)
        print(f"  tablas eliminadas de {engine_path}")

    init_tenant_db(tenant_id)
    with Session(get_tenant_engine(tenant_id)) as session:
        # ── Users ──────────────────────────────────────────────────────
        user_ids: dict[str, str] = {}
        user_service = UserService(session)
        for username, email, password, rol in USERS:
            user = user_service.create_user(
                tenant_id=tenant_id,
                username=username,
                email=email,
                password=password,
                rol=rol,
            )
            user_ids[username] = user.id
        print(f"  users: {len(user_ids)} creados")

        # ── Plant ──────────────────────────────────────────────────────
        plant_repo = BaseRepository(Plant, session)
        plant_repo.create(
            {
                "id": PLANT_ID,
                "tenant_id": tenant_id,
                "nombre": "Planta Norte",
                "direccion": "Ruta 8 km 12, Paraje El Sauce",
            }
        )
        print(f"  plants: 1 creada ({PLANT_ID})")

        # ── Water sources ──────────────────────────────────────────────
        source_repo = BaseRepository(WaterSource, session)
        source_ids: dict[str, str] = {}
        for source_id, tipo, nombre, ubicacion in SOURCES:
            source_repo.create(
                {
                    "id": source_id,
                    "planta_id": PLANT_ID,
                    "tipo": tipo,
                    "nombre": nombre,
                    "ubicacion": ubicacion,
                }
            )
            source_ids[nombre] = source_id
        print(f"  water_sources: {len(source_ids)} creadas")

        # ── Sampling frequencies ───────────────────────────────────────
        # Chlorine is checked twice a day on every source; the rest are
        # weekly or monthly.
        frequency_repo = BaseRepository(SamplingFrequency, session)
        source_names = [nombre for _, _, nombre, _ in SOURCES]
        for nombre in source_names:
            for tipo_analisis_id, frecuencia, hora in [
                ("at-cloro", "DIARIA", "06:00"),
                ("at-cloro", "DIARIA", "14:00"),
                ("at-fq", "SEMANAL", "09:00"),
                ("at-mb", "MENSUAL", "10:00"),
            ]:
                frequency_repo.create(
                    {
                        "fuente_id": source_ids[nombre],
                        "tipo_analisis_id": tipo_analisis_id,
                        "frecuencia": frecuencia,
                        "hora_esperada": hora,
                    }
                )
        print(f"  sampling_frequencies: creadas para {len(source_names)} fuentes")

        # ── Sample history ─────────────────────────────────────────────
        # Backdated through the repository so history spans several days and
        # chlorine appears multiple times per day on the same source.
        sample_repo = BaseRepository(SampleRecord, session)
        operario_id = user_ids["operario"]
        today = datetime.now(timezone.utc).date()
        sample_count = 0
        for days_ago in range(6, -1, -1):
            day = today - timedelta(days=days_ago)
            # Two chlorine rounds per grifo, plus one weekly physico-chemical.
            for hour, minute in [(6, 15), (14, 40)]:
                for nombre in source_names:
                    sample_repo.create(
                        {
                            "tenant_id": tenant_id,
                            "fuente_id": source_ids[nombre],
                            "tipo_analisis_id": "at-cloro",
                            "operario_id": operario_id,
                            "fecha": day.isoformat(),
                            "hora": f"{hour:02d}:{minute:02d}:00",
                            "sincronizada": True,
                            "created_at": datetime.combine(
                                day, datetime.min.time(), tzinfo=timezone.utc
                            )
                            .replace(hour=hour, minute=minute)
                            .isoformat(),
                        }
                    )
                    sample_count += 1
            if days_ago % 2 == 0:
                sample_repo.create(
                    {
                        "tenant_id": tenant_id,
                        "fuente_id": source_ids["Pozo Norte"],
                        "tipo_analisis_id": "at-fq",
                        "operario_id": operario_id,
                        "fecha": day.isoformat(),
                        "hora": "09:20:00",
                        "sincronizada": True,
                        "created_at": datetime.combine(
                            day, datetime.min.time(), tzinfo=timezone.utc
                        )
                        .replace(hour=9, minute=20)
                        .isoformat(),
                    }
                )
                sample_count += 1
        print(f"  sample_records: {sample_count} creados (ultimos 7 dias)")

        # ── Alerts ─────────────────────────────────────────────────────
        # Nothing in the backend generates alerts, so they are seeded here to
        # exercise the M1.7 screen. The offset is in days and its sign carries
        # the meaning: overdue alerts sit in the past, scheduled ones ahead.
        alert_repo = BaseRepository(Alert, session)
        alert_specs = [
            ("PENDIENTE", "Grifo Cocina", "at-cloro", 0),
            ("PENDIENTE", "Grifo Limpieza", "at-cloro", 0),
            ("VENCIDA", "Grifo Bebedero", "at-fq", -2),
            ("VENCIDA", "Pozo Sur", "at-mb", -4),
            ("PROGRAMADA", "Pozo Norte", "at-mb", 3),
        ]
        for tipo, nombre, tipo_analisis_id, offset in alert_specs:
            alert_repo.create(
                {
                    "tenant_id": tenant_id,
                    "usuario_id": operario_id,
                    "tipo": tipo,
                    "fuente_id": source_ids[nombre],
                    "tipo_analisis_id": tipo_analisis_id,
                    "fecha_esperada": (today + timedelta(days=offset)).isoformat(),
                    "leida": False,
                }
            )
        print(f"  alerts: {len(alert_specs)} creados (ninguna leida)")

    return tenant_id


def main() -> int:
    parser = argparse.ArgumentParser(description="Seed datos de demo para Agua")
    parser.add_argument("--tenant-id", default=TENANT_ID, help="ID del tenant (default: demo)")
    parser.add_argument("--reset", action="store_true", help="Recrea el tenant desde cero")
    args = parser.parse_args()

    print(f"\nSeeding tenant '{args.tenant_id}'\n")
    if not args.reset and Path("./data/tenants", args.tenant_id, "agua.db").exists():
        print(f"El tenant '{args.tenant_id}' ya existe. Usá --reset para recrearlo.")
        return 1

    seed_analysis_types()
    result = seed_tenant(args.tenant_id, args.reset)

    if result is None:
        return 1

    print("\n" + "=" * 58)
    print("DATOS DE DEMO LISTOS")
    print("=" * 58)
    print(f"\n  ID de Empresa: {args.tenant_id}\n")
    print("  Usuarios:")
    for username, email, password, rol in USERS:
        print(f"    {rol:<14} {username:<10} {password}")
    print("\n  API:      http://localhost:8000")
    print("  Frontend: http://localhost:8080")
    print("\n  En la app: Configuracion -> ID de Empresa = "
          f"'{args.tenant_id}'\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
