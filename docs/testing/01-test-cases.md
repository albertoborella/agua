# Casos de Prueba

Cada caso de prueba se deriva de una regla de negocio (BN), requisito
funcional (RF) o caso de uso (UC). El prefijo `TC-` identifica cada caso.

---

## 1. Autenticacion

### TC-AUTH-001: Login con credenciales correctas

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-005, RF-005, UC-AUTH-001 |
| **Precondicion** | Usuario existente y activo con credenciales validas. |
| **Pasos** | 1. POST /auth/login con usuario y contrasena correctos. |
| **Resultado esperado** | 200 OK con access_token y refresh_token. |

### TC-AUTH-002: Login con contrasena incorrecta

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-005, UC-AUTH-001 |
| **Pasos** | 1. POST /auth/login con contrasena incorrecta. |
| **Resultado esperado** | 401 Unauthorized. |

### TC-AUTH-003: Login con usuario inexistente

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-005, UC-AUTH-001 |
| **Pasos** | 1. POST /auth/login con usuario que no existe. |
| **Resultado esperado** | 401 Unauthorized. |

### TC-AUTH-004: Login con usuario desactivado

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-005, UC-AUTH-001 |
| **Precondicion** | Usuario con activo=0. |
| **Pasos** | 1. POST /auth/login con credenciales validas. |
| **Resultado esperado** | 403 Forbidden. |

### TC-AUTH-005: Bloqueo tras 5 intentos fallidos

| Campo | Valor |
| ----- | ----- |
| **Referencia** | RF-005, UC-AUTH-001 |
| **Pasos** | 1. POST /auth/login 5 veces con contrasena incorrecta. |
| **Resultado esperado** | 5ta respuesta: 429 Too Many Requests. |

### TC-AUTH-006: Refresh token exitoso

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-AUTH-001 |
| **Precondicion** | Refresh token valido. |
| **Pasos** | 1. POST /auth/refresh con refresh_token valido. |
| **Resultado esperado** | 200 OK con nuevo access_token. |

### TC-AUTH-007: Refresh token expirado

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-AUTH-001 |
| **Pasos** | 1. POST /auth/refresh con refresh_token expirado. |
| **Resultado esperado** | 401 Unauthorized. |

### TC-AUTH-008: Cambio de contrasena exitoso

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-004, RF-004, UC-AUTH-002 |
| **Pasos** | 1. POST /auth/change-password con contrasena actual, nueva y confirmacion. |
| **Resultado esperado** | 200 OK. La nueva contrasena funciona en el proximo login. |

### TC-AUTH-009: Cambio de contrasena con actual incorrecta

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-AUTH-002 |
| **Pasos** | 1. POST /auth/change-password con contrasena actual incorrecta. |
| **Resultado esperado** | 400 Bad Request. |

### TC-AUTH-010: Cambio de contrasena que no cumple politica

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-AUTH-002 |
| **Pasos** | 1. POST /auth/change-password con contrasena de 4 caracteres. |
| **Resultado esperado** | 400 Bad Request con errores de validacion. |

### TC-AUTH-011: Admin restablece contrasena de usuario

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-AUTH-003 |
| **Pasos** | 1. POST /admin/users/{id}/reset-password con nueva contrasena. |
| **Resultado esperado** | 200 OK. El usuario puede login con la nueva contrasena. |

---

## 2. Configuracion (Administrador)

### TC-ADM-001: Crear planta

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-ADM-001 |
| **Pasos** | 1. POST /admin/plants con nombre y direccion. |
| **Resultado esperado** | 201 Created con la planta creada. |

### TC-ADM-002: Crear grifo

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-010, RF-010, UC-ADM-002 |
| **Pasos** | 1. POST /admin/water-sources con tipo=GRIFO, nombre, ubicacion. |
| **Resultado esperado** | 201 Created con el grifo creado. |

### TC-ADM-003: Editar grifo

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-010, RF-011, UC-ADM-002 |
| **Pasos** | 1. PUT /admin/water-sources/{id} con nuevo nombre. |
| **Resultado esperado** | 200 OK con datos actualizados. |

### TC-ADM-004: Desactivar grifo

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-012, RF-011, UC-ADM-002 |
| **Pasos** | 1. DELETE /admin/water-sources/{id}. |
| **Resultado esperado** | 200 OK. El grifo no aparece en fuentes activas. |

### TC-ADM-005: Grifo desactivado no visible para operario

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-012, RF-015 |
| **Pasos** | 1. GET /samples/sources con token de operario. |
| **Resultado esperado** | 200 OK. El grifo desactivado NO aparece. |

### TC-ADM-006: Crear pozo

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-011, RF-012, RF-013, UC-ADM-003 |
| **Pasos** | 1. POST /admin/water-sources con tipo=POZO. |
| **Resultado esperado** | 201 Created con el pozo creado. |

### TC-ADM-007: Configurar tipo de analisis

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-014, RF-016, UC-ADM-004 |
| **Pasos** | 1. POST /admin/analysis-types con codigo y nombre. |
| **Resultado esperado** | 201 Created. El tipo aparece en el select del operario. |

### TC-ADM-008: Configurar frecuencia de muestreo

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-013, RF-014, UC-ADM-005 |
| **Pasos** | 1. POST /admin/frequencies con fuente, tipo, frecuencia=DIARIA, hora_esperada. |
| **Resultado esperado** | 201 Created. El sistema genera alertas segun esta frecuencia. |

### TC-ADM-009: Crear usuario

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-003, RF-002, RF-003, UC-ADM-006 |
| **Pasos** | 1. POST /admin/users con username, email, password, rol=OPERARIO. |
| **Resultado esperado** | 201 Created. El usuario puede iniciar sesion. |

### TC-ADM-010: Crear usuario con username duplicado

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-ADM-006 |
| **Pasos** | 1. POST /admin/users con username ya existente. |
| **Resultado esperado** | 409 Conflict. |

### TC-ADM-011: Desactivar usuario

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-ADM-006 |
| **Pasos** | 1. DELETE /admin/users/{id}. |
| **Resultado esperado** | 200 OK. El usuario no puede iniciar sesion. |

---

## 3. Registro de Muestras

### TC-SAM-001: Registrar muestra de cloro con seleccion aleatoria

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-021a, RF-020, UC-SAM-001 |
| **Precondicion** | Operario logueado, al menos 2 grifos activos. |
| **Pasos** | 1. POST /samples con fuente_id y tipo=CLORO. |
| **Resultado esperado** | 201 Created. La muestra tiene fecha/hora automaticas y el operario correcto. |

### TC-SAM-002: Cambiar fuente seleccionada aleatoriamente

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-021a, RF-020a, UC-SAM-001 |
| **Pasos** | 1. POST /samples con fuente_id diferente a la sugerida. |
| **Resultado esperado** | 201 Created con la fuente elegida por el operario. |

### TC-SAM-003: Registrar muestra de FQ

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-020, BN-022, UC-SAM-002 |
| **Pasos** | 1. POST /samples con fuente_id y tipo=FQ. |
| **Resultado esperado** | 201 Created con los campos correctos. |

### TC-SAM-004: Registrar muestra de MB

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-020, BN-022, UC-SAM-002 |
| **Pasos** | 1. POST /samples con fuente_id y tipo=MB. |
| **Resultado esperado** | 201 Created. |

### TC-SAM-005: Registrar muestra de tipo configurado por admin

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-021, RF-021, UC-SAM-003 |
| **Pasos** | 1. POST /samples con fuente_id y tipo=custom_type_id. |
| **Resultado esperado** | 201 Created. |

### TC-SAM-006: Fecha y hora son automaticas

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-023, RF-023 |
| **Pasos** | 1. POST /samples. 2. Inspeccionar respuesta. |
| **Resultado esperado** | fecha y hora coinciden con el timestamp del servidor. |

### TC-SAM-007: Muestra asociada al operario logueado

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-022, RF-024 |
| **Pasos** | 1. POST /samples con token de operario X. 2. GET /samples/{id}. |
| **Resultado esperado** | operario_id = X. |

### TC-SAM-008: Multiples tomas de cloro en un mismo dia

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-024, RF-025, UC-SAM-001 |
| **Pasos** | 1. POST /samples con tipo=CLORO, fuente=A. 2. POST /samples con tipo=CLORO, fuente=A (de nuevo). |
| **Resultado esperado** | Ambas requests retornan 201 Created. |

### TC-SAM-009: Muestra offline se almacena localmente

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-026, RF-026, UC-SAM-001 |
| **Pasos** | 1. Simular sin conexion. 2. Registrar muestra en la app. 3. Verificar almacenamiento local. |
| **Resultado esperado** | La muestra queda en SQLite local con sincronizada=0. |

### TC-SAM-010: Sincronizacion de muestras offline

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-026, RF-026 |
| **Pasos** | 1. Crear 3 muestras offline. 2. Restaurar conexion. 3. Ejecutar sync. |
| **Resultado esperado** | Las 3 muestras se suben al backend y se marcan sincronizada=1. |

### TC-SAM-011: Ver muestras del dia

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-SAM-004, RF-041 |
| **Pasos** | 1. GET /samples/today con token de operario. |
| **Resultado esperado** | 200 OK con listado de muestras del dia actual del operario. |

### TC-SAM-012: Ver historial con filtros

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-SAM-005, RF-040 |
| **Pasos** | 1. GET /samples/history?fuente_id=X&tipo_analisis_id=Y&fecha_desde=2026-09-01. |
| **Resultado esperado** | 200 OK con muestras que cumplen los filtros. |

---

## 4. Alertas

### TC-ALT-001: Generacion automatica de alerta pendiente

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-030, UC-ALT-003 |
| **Precondicion** | Frecuencia diaria de cloro configurada, sin muestra registrada hoy. |
| **Pasos** | 1. Ejecutar job de evaluacion de alertas. |
| **Resultado esperado** | Se genera alerta tipo PENDIENTE para el operario de esa planta. |

### TC-ALT-002: Generacion de alerta vencida

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-032, UC-ALT-003 |
| **Precondicion** | Frecuencia con fecha pasada y sin muestra registrada. |
| **Pasos** | 1. Ejecutar job de evaluacion de alertas. |
| **Resultado esperado** | Se genera alerta tipo VENCIDA. |

### TC-ALT-003: Generacion de alerta programada

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-031, UC-ALT-003 |
| **Precondicion** | Frecuencia de FQ semanal para proximo lunes. |
| **Pasos** | 1. Ejecutar job de evaluacion de alertas un viernes anterior. |
| **Resultado esperado** | Se genera alerta tipo PROGRAMADA con fecha_esperada del lunes. |

### TC-ALT-004: Alertas visibles solo de la planta del operario

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-033, UC-ALT-001 |
| **Precondicion** | Operario de planta A logueado. Alertas existentes para plantas A y B. |
| **Pasos** | 1. GET /alerts/pending con token del operario. |
| **Resultado esperado** | Solo aparecen alertas de la planta A. |

### TC-ALT-005: Marcar alerta como leida

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-ALT-002 |
| **Pasos** | 1. PUT /alerts/{id}/read. |
| **Resultado esperado** | 200 OK. La alerta se marca leida=1 y desaparece de la vista principal. |

### TC-ALT-006: Cloro con muestra registrada no genera alerta

| Campo | Valor |
| ----- | ----- |
| **Referencia** | UC-ALT-004 |
| **Precondicion** | Frecuencia diaria de cloro, muestra ya registrada hoy. |
| **Pasos** | 1. Ejecutar job de evaluacion de alertas. |
| **Resultado esperado** | No se genera alerta pendiente para esa fuente + dia. |

### TC-ALT-007: Alertas del dia en pantalla principal

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-033, RF-030, RF-041 |
| **Pasos** | 1. Login como operario. 2. Ver pantalla principal. |
| **Resultado esperado** | Se muestran pendientes, realizadas y vencidas del dia. |

---

## 5. Aislamiento Multi-Tenant

### TC-TEN-001: Operario no ve datos de otro tenant

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-022 |
| **Precondicion** | Operario del tenant A logueado. Muestras existentes en tenant B. |
| **Pasos** | 1. GET /samples/history con token del tenant A. |
| **Resultado esperado** | Solo aparecen muestras del tenant A. |

### TC-TEN-002: Admin no ve usuarios de otro tenant

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-003 |
| **Pasos** | 1. GET /admin/users con token del tenant A. |
| **Resultado esperado** | Solo aparecen usuarios del tenant A. |

### TC-TEN-003: Token de un tenant no accede a datos de otro

| Campo | Valor |
| ----- | ----- |
| **Referencia** | BN-022 |
| **Pasos** | 1. GET /samples/history con token del tenant A pasando un fuente_id del tenant B. |
| **Resultado esperado** | 404 Not Found o lista vacia (nunca datos del tenant B). |
