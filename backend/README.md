# Agua - Backend

Sistema multi-tenant de control de calidad de agua potable.

## Inicio rápido

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
- `app/services/` — Lógica de negocio
- `app/repositories/` — Acceso a datos genérico
- `app/middleware/` — JWT auth y tenant extraction
- `scripts/` — CLI scripts

## API Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/auth/login` | Login (requiere `client_id` = tenant_id) |
| POST | `/auth/refresh` | Refrescar access token |
| POST | `/auth/change-password` | Cambiar contraseña |
| CRUD | `/admin/plants` | CRUD de plantas |
| CRUD | `/admin/sources` | CRUD de fuentes de agua |
| CRUD | `/admin/analysis-types` | Catálogo global de análisis |
| CRUD | `/admin/frequencies` | Frecuencias de muestreo |
| CRUD | `/admin/users` | CRUD de usuarios |
| POST | `/samples` | Registrar muestra |
| GET | `/samples/today` | Muestras de hoy |
| GET | `/samples/history` | Historial con filtros |
| GET | `/alerts/pending` | Alertas pendientes |
| PUT | `/alerts/{id}/read` | Marcar alerta leída |
