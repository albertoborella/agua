# Agua - Backend

Sistema multi-tenant de control de calidad de agua potable.

## Stack

- **Python 3.12+** / **FastAPI** — API REST async
- **SQLModel** — ORM + schemas (SQLAlchemy + Pydantic)
- **SQLite3** — Base de datos por tenant (archivo `.db`)
- **JWT** — Autenticacion stateless (access + refresh tokens)
- **Podman** — Contenedores (sin daemon)
- **AWS ECR Public** — Imagenes base (`public.ecr.aws/docker/library/python:3.12-slim`)

## Inicio rapido

### Opcion 1: podman-compose (recomendado)

```bash
# Desde la raiz del proyecto
podman-compose up --build

# O en background
podman-compose up -d
```

La API queda disponible en:
- **URL**: http://localhost:8000
- **Docs**: http://localhost:8000/docs
- **Health**: http://localhost:8000/health

### Opcion 2: build manual con Podman

```bash
cd backend
./build.sh
```

### Opcion 3: desarrollo local (sin contenedor)

```bash
cd backend
pip install -r requirements.txt

# Crear primer superadmin
python scripts/createsuperadmin.py \
    --tenant-name "Mi Empresa" \
    --admin-username admin \
    --admin-email admin@example.com \
    --admin-password secret123

# Ejecutar el servidor
uvicorn app.main:app --reload
```

## Estructura

- `app/models/` — Modelos SQLModel ( SQLAlchemy + Pydantic )
- `app/schemas/` — Schemas de request/response
- `app/routers/` — Endpoints FastAPI
- `app/services/` — Logica de negocio
- `app/repositories/` — Acceso a datos generico
- `app/middleware/` — JWT auth y tenant extraction
- `scripts/` — CLI scripts
- `Containerfile` — Build de imagen Podman (AWS ECR)
- `build.sh` — Script helper para build/run

## Comandos utiles (contenedor)

```bash
# Ver logs
podman logs agua-backend

# Shell dentro del contenedor
podman exec -it agua-backend bash

# Detener
podman stop agua-backend

# Reconstruir
podman-compose up --build --force-recreate
```

## API Endpoints

| Metodo | Ruta | Descripcion |
|--------|------|-------------|
| POST | `/auth/login` | Login (requiere `client_id` = tenant_id) |
| POST | `/auth/refresh` | Refrescar access token |
| POST | `/auth/change-password` | Cambiar contrasena |
| CRUD | `/admin/plants` | CRUD de plantas |
| CRUD | `/admin/sources` | CRUD de fuentes de agua |
| CRUD | `/admin/analysis-types` | Catalogo global de analisis |
| CRUD | `/admin/frequencies` | Frecuencias de muestreo |
| CRUD | `/admin/users` | CRUD de usuarios |
| POST | `/samples` | Registrar muestra |
| GET | `/samples/today` | Muestras de hoy |
| GET | `/samples/history` | Historial con filtros |
| GET | `/alerts/pending` | Alertas pendientes |
| PUT | `/alerts/{id}/read` | Marcar alerta leida |
