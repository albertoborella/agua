# Decisions

Registro de Decisiones de Arquitectura (ADR): decisiones importantes, su
contexto, la alternativa elegida y el motivo.

---

## ADRs Registrados

Los ADRs del proyecto estan documentados en `docs/architecture/04-decisions.md`.

| ADR | Fecha | Decision |
| --- | ------- | -------- |
| ADR-001 | 2026-09-20 | Backend: Python FastAPI + SQLModel |
| ADR-002 | 2026-09-20 | Frontend: Flutter (iOS + Android) |
| ADR-003 | 2026-09-20 | Base de datos: SQLite3 por tenant |
| ADR-004 | 2026-09-20 | Multi-tenant: base de datos por tenant |
| ADR-005 | 2026-09-20 | Autenticacion: JWT (access + refresh) |
| ADR-006 | 2026-09-20 | Offline-first: SQLite local + sync |
| ADR-007 | 2026-09-20 | Primer admin por script (createsuperadmin) |

## Formato ADR

Para nuevos ADRs, seguir el formato en `docs/architecture/04-decisions.md`.

## Consejos

- Un ADR se escribe cuando se TOMA la decision, no despues.
- Los ADRs son inmutables: si la decision cambia, se crea un ADR nuevo.
