# Decisiones Tecnicas (Indice)

Registro de las decisiones de arquitectura tomadas en el proyecto.

---

## Decisiones Registradas

| ADR | Fecha | Decision | Estado |
| --- | ------- | -------- | ------ |
| ADR-001 | 2026-09-20 | Backend: Python FastAPI + SQLModel | Aprobada |
| ADR-002 | 2026-09-20 | Frontend: Flutter (iOS + Android) | Aprobada |
| ADR-003 | 2026-09-20 | Base de datos: SQLite3 por tenant | Aprobada |
| ADR-004 | 2026-09-20 | Multi-tenant: base de datos por tenant | Aprobada |
| ADR-005 | 2026-09-20 | Autenticacion: JWT (access + refresh) | Aprobada |
| ADR-006 | 2026-09-20 | Offline-first: SQLite local + sync | Aprobada |
| ADR-007 | 2026-09-20 | Primer admin por script (createsuperadmin) | Aprobada |

---

## ADR-001: Backend Python FastAPI + SQLModel

**Contexto**: Se necesita un backend REST para servir a app movil Flutter.

**Decision**: FastAPI con SQLModel como ORM/schema layer.

**Alternativas descartadas**:
- Django REST Framework: mas pesado, menos idoneo para APIs moviles.
- Flask: menos estructura, sin tipado nativo.
- SQLAlchemy puro: SQLModel lo complementa con Pydantic integrado.

**Consecuencias**:
- (+) Tipado estricto, documentacion OpenAPI automatica, alto rendimiento async.
- (+) SQLModel unifica validacion Pydantic y mapeo SQLAlchemy.
- (-) Ecosistema mas joven que Django.

---

## ADR-002: Frontend Flutter

**Contexto**: Se necesita app movil para iOS y Android.

**Decision**: Flutter con una sola base de codigo.

**Alternativas descartadas**:
- React Native: performance inferior para apps con SQLite local.
- Apps nativas (Swift/Kotlin): dos codebases, mas costo de mantenimiento.

**Consecuencias**:
- (+) Una sola codebase, hot reload, performance nativa.
- (-) Dominio Dart menos comun que TypeScript/JavaScript.

---

## ADR-003: SQLite3 por Tenant

**Contexto**: Se necesita persistencia de datos sin infraestructura externa
para el MVP.

**Decision**: Cada tenant tiene su propio archivo SQLite3.

**Alternativas descartadas**:
- PostgreSQL compartido: mas complejo, requiere infraestructura.
- SQLite3 compartido (multi-tenant en un archivo): mas complejo de backup
  y aislamiento.

**Consecuencias**:
- (+) Sin dependencias externas, backup por archivo, aislamiento total.
- (-) Sin concurrencia de escritura entre procesos (aceptable para MVP).
- (-) Limite practico de ~100 usuarios concurrentes por tenant.

---

## ADR-006: Offline-First

**Contexto**: Los operarios trabajan en plantas con conectividad
intermitente.

**Decision**: La app almacena muestras localmente y sincroniza cuando hay
red.

**Alternativas descartadas**:
- Solo online: no funciona en plantas sin señal.
- Cola de mensajes: mas complejo, innecesario para el volumen MVP.

**Consecuencias**:
- (+) El operario nunca se queda sin poder registrar muestras.
- (-) Hay que manejar conflictos de sincronizacion (el mismo registro
  local puede haber sido creado offline).
- (-) Duplica la capa de persistencia (SQLite local + SQLite remoto).
