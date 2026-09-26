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
| ADR-008 | 2026-09-21 | Contenedores: Podman + AWS ECR Public | Aprobada |
| ADR-009 | 2026-09-21 | Flutter Web: desarrollo con hot reload en navegador | Aprobada |

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

---

## ADR-008: Contenedores Podman + AWS ECR Public

**Contexto**: Se necesita empaquetar el backend en contenedores para
desarrollo local y despliegue consistente.

**Decision**: Podman como runtime de contenedores, imagenes base desde
AWS ECR Public (`public.ecr.aws/docker/library/`).

**Alternativas descartadas**:
- Docker: requiere daemon centralizado, tiene rate limits en Docker Hub,
  politicas empresariales que restringen su uso.
- Docker Hub como registry: rate limits de descarga, autenticacion
  requerida para volumen alto.
- Buildah/Slim manual: mas complejo, sin soporte de compose nativo.

**Consecuencias**:
- (+) Sin daemon (rootless por defecto), mejor seguridad.
- (+) Sin rate limits ni autenticacion para imagenes publicas de AWS.
- (+) Compatibilidad sintactica con Dockerfiles existentes.
- (+) `podman-compose` proporciona orquestacion similar a docker-compose.
- (-) Algunas herramientas de ecosistema Docker no son compatibles.
- (-) Curva de aprendizaje minima para equipos acostumbrados a Docker.

---

## ADR-009: Flutter Web — Desarrollo con Hot Reload en Navegador

**Contexto**: El equipo quiere ver los cambios de UI en un navegador mientras
desarrollan, sin compilar para movil cada vez. Flutter soporta web nativamente
desde Flutter 2.

**Decision**: Habilitar Flutter Web para desarrollo local con hot reload,
usando un container Podman con el SDK de Flutter y `flutter run -d web-server`.

**Alternativas descartadas**:
- Instalar Flutter localmente: inconsistencia entre desarrolladores, sin
  reproducibilidad del entorno.
- Solo compilar para movil: ciclo de desarrollo lento, no se puede iterar
  rapido en UI.
- React Native Web: requiere migrar toda la codebase, perder offline-first.

**Implementacion**:
- `mobile/Containerfile`: imagen basada en `ubuntu:24.04` (ECR Public) con
  Flutter SDK pre-instalado.
- `podman-compose.yml`: servicio `flutter-web` que monta el codigo fuente
  via volume para hot reload.
- `lib/core/config/env_config.dart`: detecta `kIsWeb` y usa `localhost:8000`
  en vez de `10.0.2.2:8000` (Android emulator).
- Puerto 8080 expuesto para acceso desde el navegador del host.

**Consecuencias**:
- (+) Hot reload en navegador: cambios instantaneos sin recompilar.
- (+) Misma codebase para movil y web (sin dependencias nativas).
- (+) Entorno reproducible via Podman (mismo SDK en todos los equipos).
- (+) No afecta el build de movil (Android/iOS siguen igual).
- (-) Algunos plugins de Flutter no soportan web (verificar compatibilidad).
- (-) El container de Flutter pesa ~2GB (SDK + cache).
- (-) Hot reload via volume mount puede tener latencia en OS con filesystem
  lento (resoluble con `PUB_CACHE` en volumen separado).
