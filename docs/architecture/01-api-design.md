# Diseno de API

## Convenciones

- Base URL: `https://api.agua.example.com/v1`
- Formato: JSON (`Content-Type: application/json`)
- Autenticacion: Bearer token JWT en header `Authorization`
- Multi-tenant: el tenant se resuelve desde el JWT, nunca en la URL
- Errores: formato estandar HTTP con body JSON

## Estructura de Respuesta (Exito)

```json
{
  "data": { ... },
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 150
  }
}
```

## Estructura de Respuesta (Error)

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "El nombre del grifo es requerido",
    "details": [
      {"field": "nombre", "issue": "required"}
    ]
  }
}
```

## Endpoints

### Auth

| Metodo | Endpoint | Descripcion | Auth |
| ------ | -------- | ----------- | ---- |
| POST | `/auth/login` | Iniciar sesion, retorna access + refresh token. | No |
| POST | `/auth/refresh` | Renovar access token con refresh token. | Refresh token |
| POST | `/auth/change-password` | Cambiar contrasena propia. | Si |
| POST | `/auth/reset-password` | Admin resetea contrasena de un usuario. | Admin |

### Admin - Usuarios

| Metodo | Endpoint | Descripcion | Auth |
| ------ | -------- | ----------- | ---- |
| GET | `/admin/users` | Listar usuarios del tenant. | Admin |
| POST | `/admin/users` | Crear usuario. | Admin |
| PUT | `/admin/users/{id}` | Editar usuario. | Admin |
| DELETE | `/admin/users/{id}` | Desactivar usuario. | Admin |
| POST | `/admin/users/{id}/reset-password` | Restablecer contrasena. | Admin |

### Admin - Configuracion

| Metodo | Endpoint | Descripcion | Auth |
| ------ | -------- | ----------- | ---- |
| GET | `/admin/plants` | Listar plantas. | Admin |
| POST | `/admin/plants` | Crear planta. | Admin |
| PUT | `/admin/plants/{id}` | Editar planta. | Admin |
| GET | `/admin/water-sources` | Listar grifos/ pozos. | Admin |
| POST | `/admin/water-sources` | Crear fuente de agua. | Admin |
| PUT | `/admin/water-sources/{id}` | Editar fuente. | Admin |
| DELETE | `/admin/water-sources/{id}` | Desactivar fuente. | Admin |
| GET | `/admin/frequencies` | Listar frecuencias. | Admin |
| POST | `/admin/frequencies` | Crear frecuencia. | Admin |
| PUT | `/admin/frequencies/{id}` | Editar frecuencia. | Admin |

### Operario - Muestras

| Metodo | Endpoint | Descripcion | Auth |
| ------ | -------- | ----------- | ---- |
| GET | `/samples/sources` | Listar fuentes activas. | Operario |
| GET | `/samples/today` | Muestras del dia del operario. | Operario |
| POST | `/samples` | Registrar una muestra. | Operario |
| GET | `/samples/history` | Historial de muestras (filtros: fuente, fecha, tipo). | Operario |
| GET | `/samples/{id}` | Detalle de una muestra. | Operario |

### Alertas

| Metodo | Endpoint | Descripcion | Auth |
| ------ | -------- | ----------- | ---- |
| GET | `/alerts/pending` | Alertas pendientes del operario. | Operario |
| PUT | `/alerts/{id}/read` | Marcar alerta como leida. | Operario |

### Catalogos

| Metodo | Endpoint | Descripcion | Auth |
| ------ | -------- | ----------- | ---- |
| GET | `/catalog/analysis-types` | Tipos de analisis disponibles. | Cualquier usuario |

## Squema de Registro de Muestra (POST /samples)

```json
// Request
{
  "fuente_id": "uuid-del-grifo",
  "tipo_analisis_id": "at-cloro",
  "descripcion_otro": null
}

// Response 201
{
  "data": {
    "id": "uuid-nuevo",
    "fuente_id": "uuid-del-grifo",
    "fuente_nombre": "Grifo Sector A",
    "tipo_analisis_id": "at-cloro",
    "tipo_analisis_nombre": "Nivel de Cloro",
    "operario_id": "uuid-operario",
    "operario_nombre": "Juan Perez",
    "fecha": "2026-09-20",
    "hora": "14:32:05",
    "created_at": "2026-09-20T14:32:05Z"
  }
}
```

## Paginacion

Todos los endpoints de listado soportan:

| Parametro | Default | Descripcion |
| --------- | ------- | ----------- |
| `page` | 1 | Numero de pagina. |
| `per_page` | 20 | Elementos por pagina (max 100). |

## Filtros

| Endpoint | Filtros soportados |
| -------- | ------------------ |
| `/samples/history` | `fuente_id`, `tipo_analisis_id`, `fecha_desde`, `fecha_hasta`, `operario_id` |
| `/admin/users` | `rol`, `activo` |
| `/alerts/pending` | `tipo` |
