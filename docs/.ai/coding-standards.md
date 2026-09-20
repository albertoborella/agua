# Coding Standards

## Python (Backend)

### Estilo

- Seguir **PEP 8**.
- Maximo 88 caracteres por linea (Black formatter).
- Usar **Black** para formateo automatico.
- Usar **Ruff** para linting.

### Estructura de Archivos

```
backend/app/
├── main.py              ← Punto de entrada FastAPI
├── config.py            ← Settings con pydantic-settings
├── database.py          ← Engine y session
├── models/              ← SQLModel models (tablas)
├── schemas/             ← Pydantic schemas (request/response)
├── routers/             ← Endpoints FastAPI
├── services/            ← Logica de negocio
├── repositories/        ← Acceso a datos
└── middleware/          ← Tenant, auth, etc.
```

### Naming

| Tipo | Convencion | Ejemplo |
| ---- | ---------- | ------- |
| Archivos | `snake_case.py` | `sample_service.py` |
| Clases | `PascalCase` | `SampleRecord` |
| Funciones | `snake_case` | `create_sample()` |
| Variables | `snake_case` | `tenant_id` |
| Constants | `UPPER_SNAKE` | `JWT_ALGORITHM` |
| Endpoints | `kebab-case` | `/water-sources` |

### Reglas

- Todas las funciones publicas deben tener docstring.
- Usar type hints en todos los parametros y retornos.
- No usar `**kwargs` en functions publicas.
- Los services no importan de routers; los routers importan de services.
- Los repositories no tienen logica de negocio.

## Dart (Mobile)

### Estilo

- Seguir **effective Dart**.
- Usar `dart format` para formateo.
- Usar `flutter analyze` para linting.

### Estructura de Archivos

```
mobile/lib/
├── main.dart
├── app/
│   ├── routes.dart
│   └── theme.dart
├── features/
│   ├── auth/
│   ├── home/
│   ├── samples/
│   └── alerts/
├── models/
├── services/
│   ├── api_service.dart
│   └── sync_service.dart
└── database/
    └── local_db.dart
```

### Naming

| Tipo | Convencion | Ejemplo |
| ---- | ---------- | ------- |
| Archivos | `snake_case.dart` | `sample_service.dart` |
| Clases | `PascalCase` | `SampleRecord` |
| Funciones | `camelCase` | `createSample()` |
| Variables | `camelCase` | `tenantId` |
| Constantes | `camelCase` o `UPPER_SNAKE` | `apiBaseUrl` |

### Reglas

- Todos los widgets deben ser `const` cuando sea posible.
- Preferir `StatelessWidget` sobre `StatefulWidget` cuando no hay estado.
- Extraer widgets repetidos a componentes reutilizables.
- Los servicios de API deben manejar errores explicitamente.

## SQL

- Keywords en MAYUSCULAS (`SELECT`, `FROM`, `WHERE`).
- Nombres de tablas en `snake_case` plural (`sample_records`).
- Nombres de columnas en `snake_case` (`created_at`).
- Siempre incluir `created_at` en tablas principales.
- Usar `TEXT` para UUIDs y fechas en SQLite3.
