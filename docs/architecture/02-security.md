# Seguridad

## 1. Autenticacion

### JWT (JSON Web Tokens)

El sistema usa JWT con dos tokens:

| Token | Duracion | Uso |
| ----- | -------- | --- |
| **Access token** | 30 minutos (configurable) | Acceder a endpoints protegidos. Se envia en header `Authorization: Bearer <token>`. |
| **Refresh token** | 7 dias | Renovar el access token sin reingresar credenciales. Se almacena en la app movil de forma segura. |

### Payload del JWT

```json
{
  "sub": "uuid-usuario",
  "tenant": "uuid-tenant",
  "rol": "OPERARIO",
  "exp": 1695234725,
  "iat": 1695232925
}
```

- `sub`: ID del usuario.
- `tenant`: ID del tenant (para resolver el contexto multi-tenant).
- `rol`: Rol del usuario (para autorizacion a nivel de endpoint).

### Flujo de Login

```
1. App envia POST /auth/login { username, password }
2. Backend valida credenciales contra password_hash (bcrypt)
3. Backend genera access token + refresh token
4. App almacena tokens de forma segura (flutter_secure_storage)
5. App envia access token en cada peticion
```

### Flujo de Refresh

```
1. Access token expira (401)
2. App envia POST /auth/refresh { refresh_token }
3. Backend valida refresh token y genera nuevo access token
4. App reintentar la peticion original con el nuevo token
5. Si el refresh token expira, el usuario debe reingresar
```

## 2. Autorizacion

### Control por Rol

| Rol | Acceso |
| ---- | ------ |
| **ADMIN** | Todos los endpoints de admin, lectura de todas las muestras. |
| **OPERARIO** | Registrar muestras, ver historial propio, ver alertas propias. |
| **LABORATORISTA** | Futuro: ingestar resultados de analisis. |

### Control por Tenant

Cada peticion se resuelve al tenant del token JWT. Todas las consultas
SQL incluyen `WHERE tenant_id = :tenant_id`. No existe endpoint que
retorne datos de otro tenant.

### Middlewares de Seguridad

1. **TenantMiddleware**: extrae `tenant_id` del JWT y lo inyecta en el
   contexto de la peticion.
2. **AuthMiddleware**: valida la presencia y vigencia del token JWT.
3. **RoleMiddleware**: valida que el rol del usuario tenga permiso para
   el endpoint solicitado.

## 3. Proteccion de Datos

### Contrasenas

- Almacenadas con **bcrypt** (cost factor 12).
- Nunca se almacenan en texto plano.
- Nunca se retornan en respuestas API.
- El endpoint de listado de usuarios retorna solo `id`, `username`,
  `email`, `rol` y `activo`.

### Comunicacion

- Todas las comunicaciones usan **HTTPS (TLS 1.2+)**.
- En desarrollo se permite HTTP localhost.
- HSTS habilitado en produccion.

### Datos Sensiveles

- Los refresh tokens se almacenan en `flutter_secure_storage` (Keychain
  en iOS, EncryptedSharedPreferences en Android).
- Los archivos `.db` de SQLite3 se almacenan en el directorio privado
  de la app movil y en un directorio protegido en el servidor.

## 4. Rate Limiting

| Endpoint | Limite | Ventana |
| -------- | ------ | ------- |
| `/auth/login` | 5 intentos | 15 minutos |
| `/auth/refresh` | 10 requests | 15 minutos |
| Demas endpoints | 100 requests | 1 minuto |

## 5. Validacion de Entrada

- Todos los inputs se validan con Pydantic schemas.
- Los strings se sanitizan contra inyeccion SQL (SQLModel lo hace
  automaticamente con parameterized queries).
- Los UUIDs se validan como formato v4.
- Las fechas se validan como ISO 8601.
