# Estrategia de Pruebas

## Niveles de Prueba

```
┌─────────────────────────────────────┐
│  E2E (End-to-End)                   │  Flujo completo en la app movil
├─────────────────────────────────────┤
│  Integracion (API)                  │  Endpoints FastAPI + SQLite3
├─────────────────────────────────────┤
│  Unidad (Logica de negocio)         │  Services, repositories, algoritmos
├─────────────────────────────────────┤
│  Unidad (UI)                        │  Widgets Flutter aislados
└─────────────────────────────────────┘
```

### Prueba de Unidad (Backend)

- **Que se prueba**: logica de negocio en services, validaciones en
  schemas, algoritmos (ej: seleccion aleatoria de grifo).
- **Herramienta**: `pytest` con `pytest-asyncio`.
- **Base de datos**: SQLite3 en memoria para tests aislados.
- **Cobertura minima**: 80% en services y repositories.

### Prueba de Unidad (Frontend)

- **Que se prueba**: widgets Flutter aislados, formateo de datos,
  estados de UI.
- **Herramienta**: `flutter test`.
- **Cobertura minima**: 70% en features principales.

### Prueba de Integracion (API)

- **Que se prueba**: cada endpoint contra la base de datos real
  (SQLite3 en memoria), incluyendo autenticacion, autorizacion y
  respuestas correctas.
- **Herramienta**: `pytest` con `httpx` (AsyncClient de FastAPI).
- **Fixtures**: datos de prueba pre-cargados (tenant, usuarios, fuentes,
  tipos de analisis).

### Prueba E2E (End-to-End)

- **Que se prueba**: flujos completos en la app movil simulando al
  operario y administrador.
- **Herramienta**: `flutter_test` con `integration_test`.
- **Ambiente**: backend levantado en local con datos de prueba.

## Organizacion de Tests

```
backend/
├── tests/
│   ├── conftest.py           ← Fixtures compartidos
│   ├── unit/
│   │   ├── test_services/
│   │   │   ├── test_auth_service.py
│   │   │   ├── test_sample_service.py
│   │   │   ├── test_alert_service.py
│   │   │   └── test_config_service.py
│   │   └── test_schemas/
│   │       ├── test_user_schemas.py
│   │       └── test_sample_schemas.py
│   ├── integration/
│   │   ├── test_auth_api.py
│   │   ├── test_admin_api.py
│   │   ├── test_samples_api.py
│   │   └── test_alerts_api.py
│   └── e2e/
│       └── test_full_flow.py

mobile/
├── test/
│   ├── unit/
│   │   ├── auth_test.dart
│   │   ├── samples_test.dart
│   │   └── sync_test.dart
│   ├── widget/
│   │   ├── login_widget_test.dart
│   │   ├── home_widget_test.dart
│   │   └── sample_form_widget_test.dart
│   └── integration_test/
│       └── sampling_flow_test.dart
```

## Convenciones

### Nomenclatura de Tests

```
test_<modulo>_<escenario>_<resultado_esperado>
```

Ejemplos:
- `test_auth_login_invalid_credentials_returns_401`
- `test_sample_register_cloro_creates_record_with_timestamp`
- `test_alert_generate_pending_creates_alert_for_tenant`

### Fixtures

Los fixtures se comparten via `conftest.py` y proveen:
- Tenant de prueba con datos basicos.
- Usuarios de cada rol (admin, operario, laboratorista).
- Grifos y pozos de prueba.
- Tipos de analisis pre-cargados.
- Frecuencias de muestreo de ejemplo.

### Datos de Prueba

- Cada test crea y limpia sus propios datos (rollback automatico).
- Los UUIDs se generan con `uuid.uuid4()` en los fixtures.
- Las fechas se usan como valores fijos para tests deterministas.

## Cobertura

| Modulo | Cobertura minima | Herramienta |
| ------ | ---------------- | ----------- |
| Backend services | 80% | `pytest-cov` |
| Backend repositories | 75% | `pytest-cov` |
| Backend API endpoints | 100% de endpoints | `pytest` |
| Frontend features | 70% | `flutter test --coverage` |

## Ejecucion

```bash
# Backend - todos los tests
cd backend && pytest

# Backend - solo unit
cd backend && pytest tests/unit/

# Backend - solo integracion
cd backend && pytest tests/integration/

# Backend - con cobertura
cd backend && pytest --cov=app --cov-report=html

# Frontend - todos los tests
cd mobile && flutter test

# Frontend - con cobertura
cd mobile && flutter test --coverage
```
