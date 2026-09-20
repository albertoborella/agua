# Requisitos Funcionales

## 1. Modulo de Autenticacion

| Codigo | Requisito | Regla asociada |
| ------ | --------- | --------------- |
| RF-001 | El sistema debe permitir la creacion del primer administrador mediante un script de inicializacion. | BN-001 |
| RF-002 | El administrador debe poder crear usuarios con rol asignado (Administrador, Operario, Laboratorista). | BN-003 |
| RF-003 | El administrador debe poder asignar usuario y contrasena iniciales a cada empleado. | BN-003 |
| RF-004 | El sistema debe permitir a cualquier usuario autenticado cambiar su contrasena a traves de un link. | BN-004 |
| RF-005 | El sistema debe validar credenciales y bloquear el acceso tras N intentos fallidos (configurable). | BN-005 |

## 2. Modulo de Configuracion (Administrador)

| Codigo | Requisito | Regla asociada |
| ------ | --------- | --------------- |
| RF-010 | El administrador debe poder agregar grifos con nombre, ubicacion y estado. | BN-010 |
| RF-011 | El administrador debe poder editar y desactivar grifos existentes. | BN-010, BN-012 |
| RF-012 | El administrador debe poder agregar pozos con nombre, ubicacion y estado. | BN-011 |
| RF-013 | El administrador debe poder editar y desactivar pozos existentes. | BN-011, BN-012 |
| RF-014 | El administrador debe poder configurar frecuencias de muestreo por tipo de analisis y fuente. | BN-013 |
| RF-016 | El administrador debe poder configurar la lista de tipos de analisis disponibles (nombre, codigo). | BN-014 |
| RF-015 | El sistema debe mostrar solo fuentes activas al operario al registrar muestras. | BN-012 |

## 3. Modulo de Registro de Muestras (Operario)

| Codigo | Requisito | Regla asociada |
| ------ | --------- | --------------- |
| RF-020 | Para cloro, el sistema debe seleccionar aleatoriamente un grifo/pozo de los activos y mostrarlo al operario. | BN-021a |
| RF-020a | El operario debe poder cambiar manualmente la fuente seleccionada aleatoriamente si es necesario. | BN-021a |
| RF-021 | El operario debe poder seleccionar el tipo de analisis de la lista configurada por el administrador. | BN-021 |
| RF-023 | El sistema debe registrar automaticamente la fecha y hora de la toma al confirmar. | BN-023 |
| RF-024 | El sistema debe asociar la muestra al usuario logueado (operario que la tomo). | BN-022 |
| RF-025 | El sistema debe permitir multiples tomas de cloro en un mismo dia para la misma fuente. | BN-024 |
| RF-026 | El sistema debe almacenar muestras offline y sincronizar cuando haya conectividad. | BN-026 |

## 4. Modulo de Alertas

| Codigo | Requisito | Regla asociada |
| ------ | --------- | --------------- |
| RF-030 | El sistema debe mostrar en la pantalla principal las mediciones pendientes del dia. | BN-030, BN-033 |
| RF-031 | El sistema debe notificar al operario cuando una medicion de FQ o MB esta programada para la fecha. | BN-031 |
| RF-032 | El sistema debe marcar como vencida una medicion no registrada en el plazo esperado. | BN-032 |

## 5. Modulo de Consulta

| Codigo | Requisito | Regla asociada |
| ------ | --------- | --------------- |
| RF-040 | El sistema debe mostrar un historial de muestras por fuente y por periodo. | -- |
| RF-041 | El operario debe poder ver un resumen del dia: muestras realizadas, pendientes y vencidas. | BN-033 |
