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

## Notas de implementacion (2026-09-26)

- `GET /catalog/analysis-types` esta implementado en `app/routers/catalog.py` y
  abierto a **cualquier usuario autenticado**, como indica la tabla de arriba. El
  catalogo vive en la base global y no tiene `tenant_id`, asi que leerlo no
  expone datos de ninguna empresa. Antes solo existia
  `GET /admin/analysis-types` con `require_role(["ADMIN"])`, lo que hacia
  imposible que un Operario pudiera elegir un tipo de analisis en M1.6. Ese
  endpoint de lectura se elimino para evitar dos caminos al mismo dato; las
  escrituras (`POST`/`PUT`/`DELETE`) siguen siendo solo ADMIN.
- La discriminacion de cloro es `AnalysisType.codigo == "CLORO"`. El modelo no
  tiene un booleano.
- `POST /samples` responde **200**, no 201 como dice el ejemplo de mas arriba.
- `SampleRecord` no tiene `descripcion_otro` aunque el ejemplo del request lo
  incluye, y `AnalysisType.requiere_descripcion` queda sin uso por eso.
- No hay paginacion en `GET /samples/history`.
- Ningun endpoint crea alertas: `AlertService` solo expone `get_pending` y
  `mark_read`. Las alertas se insertan a mano en `scripts/seed_demo.py`.
- La sesion guardada se resuelve en `main()`, antes de `runApp`, y la app se
  construye con un unico `MaterialApp`. La razon: `initialRoute` solo se lee
  cuando se crea el Navigator, asi que montar la app primero fijaba la ruta
  inicial a `/login` y descartaba una sesion valida en cada recarga de pagina.
  `main()` espera a `auth.init()` y recien ahi llama a `runApp`; por eso
  `AguaApp.build()` no necesita resolver nada. Cubierto por
  `mobile/test/app_boot_test.dart`.
- No hay un `GET /users` disponible para no-admins. `GET /admin/users` exige
  rol ADMIN, y `GET /samples/history` solo devuelve `operario_id`. Resolver el
  nombre de un operario que no es el usuariologueado requiere una lista de
  usuarios que el API no expone a un OPERARIO, asi que en el historial ese
  nombre no se puede resolver: `_operarioName()` muestra el username cuando el
  id coincide con el usuario de la sesion y cae a `Operario <8 chars del id>`
  para el resto.
