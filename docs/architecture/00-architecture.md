# Arquitectura General

## Vision General

**Agua** es un sistema cliente-servidor con arquitectura REST. Un backend
Python sirve a multiples clientes moviles Flutter a traves de una API HTTP.
Cada empresa (tenant) tiene su propia base de datos SQLite3 aislada.

```
┌─────────────────┐       HTTPS        ┌─────────────────────┐
│   App Movil     │ ◄────────────────► │   Backend API       │
│   (Flutter)     │                    │   (FastAPI + SQLModel)│
└─────────────────┘                    └──────────┬──────────┘
                                                  │
                                          ┌───────▼───────┐
                                          │   SQLite3     │
                                          │   (por tenant)│
                                          └───────────────┘
```

## Stack Tecnologico

| Capa | Tecnologia | Justificacion |
| ---- | ---------- | ------------- |
| **Frontend movil** | Flutter | Una sola base de codigo para iOS y Android. Dart es rapido y el hot reload acelera el desarrollo. |
| **Backend** | Python 3.12+ / FastAPI | API REST async de alto rendimiento, tipado estricto, documentacion OpenAPI automatica. |
| **ORM** | SQLModel | Combina Pydantic y SQLAlchemy en una sola capa. Ideal para FastAPI porque los modelos sirven como schemas de validacion y como mapeo a DB. |
| **Base de datos** | SQLite3 | Sin infraestructura externa, ideal para MVP y para instancias independentes por tenant. Archivo `.db` por empresa. |
| **Autenticacion** | JWT (access + refresh tokens) | Stateless, escalable, estandar para APIs REST. |
| **Contenedores** | Podman + AWS ECR Public | Podman como runtime de contenedores (sin daemon, compatible con Docker). Imagenes base desde `public.ecr.aws` para evitar dependencia de Docker Hub. |

## Patrones Arquitectonicos

### Multi-Tenant por Base de Datos

Cada empresa tiene su propio archivo SQLite3. El tenant se identifica por
el token JWT y se usa para filtrar todas las consultas.

```
data/
├── tenants/
│   ├── empresa-abc/
│   │   └── agua.db
│   ├── empresa-xyz/
│   │   └── agua.db
│   └── ...
```

**Ventaja**: aislamiento total de datos, backup por archivo, migracion
facil a PostgreSQL por tenant si escala.

**Desventaja**: no se pueden hacer joins entre tenants (no es necesario
en este dominio).

### Offline-First (Movil)

La app Flutter almacena las muestras localmente usando SQLite local
(drift o sqflite). Cuando hay conectividad, sincroniza con el backend.

```
┌──────────────────────────────┐
│         Flutter App          │
│  ┌────────────────────────┐  │
│  │  SQLite Local (drift)  │  │
│  │  - Muestras pendientes │  │
│  │  - Cache de fuentes    │  │
│  │  - Cache de alertas    │  │
│  └───────────┬────────────┘  │
│              │ sync          │
└──────────────┼───────────────┘
               ▼
        Backend API
```

### Capas del Backend

```
API Router (FastAPI)
    │
    ├── schemas/     ← Pydantic models (request/response)
    ├── services/    ← Logica de negocio
    ├── repositories/← Acceso a datos (SQLModel)
    └── models/      ← SQLModel models (tablas)
```

**Flujo de una peticion:**

1. FastAPI recibe la peticion HTTP.
2. Valida el request contra el schema Pydantic.
3. Inyecta el tenant del token JWT.
4. El repository ejecuta la consulta SQL filtrando por tenant.
5. El service aplica logica de negocio (validaciones, alertas).
6. Retorna la respuesta como JSON.

## Estructura del Proyecto

```
agua/
├── backend/
│   ├── app/
│   │   ├── main.py              ← FastAPI app, CORS, startup
│   │   ├── config.py            ← Settings, env vars
│   │   ├── database.py          ← Engine, session por tenant
│   │   ├── models/              ← SQLModel models
│   │   │   ├── tenant.py
│   │   │   ├── plant.py
│   │   │   ├── water_source.py
│   │   │   ├── user.py
│   │   │   ├── analysis_type.py
│   │   │   ├── sampling_frequency.py
│   │   │   ├── sample_record.py
│   │   │   └── alert.py
│   │   ├── schemas/             ← Pydantic request/response
│   │   ├── routers/             ← Endpoints por modulo
│   │   │   ├── auth.py
│   │   │   ├── admin.py
│   │   │   ├── samples.py
│   │   │   └── alerts.py
│   │   ├── services/            ← Logica de negocio
│   │   ├── repositories/        ← Consultas a DB
│   │   └── middleware/          ← Tenant resolution, auth
│   ├── scripts/
│   │   └── createsuperadmin.py  ← Script de inicializacion
│   ├── Containerfile            ← Build de imagen Podman (AWS ECR)
│   ├── build.sh                 ← Script helper para build/run
│   ├── requirements.txt
│   └── data/                    ← SQLite3 databases (volumen)
├── mobile/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── config/
│   │   │   │   └── env_config.dart  ← Platform-aware API URL
│   │   │   ├── theme/
│   │   │   └── constants/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── home/
│   │   │   ├── samples/
│   │   │   └── alerts/
│   │   ├── models/
│   │   └── services/
│   │       └── api_service.dart
│   ├── Containerfile            ← Flutter web dev (Podman, AWS ECR)
│   └── pubspec.yaml
├── podman-compose.yml           ← Orquestacion (backend + flutter-web)
└── docs/
```
