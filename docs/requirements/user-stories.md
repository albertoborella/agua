# User Stories

## Administrador

| ID | Historia | Criterio de aceptacion |
| -- | -------- | ---------------------- |
| US-001 | Como administrador, quiero registrar el primer usuario admin mediante un script para tener acceso inicial al sistema. | El script crea un usuario con permisos de administrador total. |
| US-002 | Como administrador, quiero crear usuarios con rol asignado para que cada empleado tenga acceso segun su funcion. | Al crear usuario se asigna nombre, contrasena y rol. El usuario puede iniciar sesion. |
| US-003 | Como administrador, quiero configurar los grifos de la planta para que el operario sepa que fuentes existen. | Puedo agregar, editar y desactivar grifos con nombre, ubicacion y estado. |
| US-004 | Como administrador, quiero configurar los pozos de la planta igual que los grifos. | Puedo agregar, editar y desactivar pozos con nombre, ubicacion y estado. |
| US-005 | Como administrador, quiero definir frecuencias de muestreo por tipo de analisis para que el sistema genere alertas automaticas. | Puedo configurar frecuencia (diaria, semanal, etc.) por analisis (Cloro, FQ, MB) y fuente. |
| US-006 | Como administrador, quiero desactivar un usuario sin eliminarlo para preservar su historial de muestras. | El usuario desactivado no puede iniciar sesion pero sus registros se mantienen. |

## Operario

| ID | Historia | Criterio de aceptacion |
| -- | -------- | ---------------------- |
| US-010 | Como operario, quiero ver los grifos y pozos disponibles para elegir de donde tomo la muestra. | La pantalla muestra solo fuentes activas con su nombre y ubicacion. |
| US-011 | Como operario, quiero seleccionar el tipo de analisis (Cloro, FQ, MB u Otro) para registrar que se esta midiendo. | Puedo elegir entre las opciones; si elijo "Otro" me pide descripcion. |
| US-012 | Como operario, quiero que la fecha y hora se registren automaticamente al confirmar la toma para no tener que ingresarlas manualmente. | Al presionar "Confirmar toma", se graba la timestamp del servidor. |
| US-013 | Como operario, quiero registrar multiples tomas de cloro en un mismo dia en el mismo grifo porque se miden varias veces. | El sistema permite duplicar registros de cloro para la misma fuente en un mismo dia. |
| US-014 | Como operario, quiero ver en la pantalla principal que mediciones tengo pendientes hoy para no olvidarme. | La vista del dia muestra mediciones pendientes, realizadas y vencidas. |
| US-015 | Como operario, quiero poder registrar muestras sin internet y que se sincronicen cuando haya conexion. | Las muestras offline se guardan localmente y se suben al sincronizar. |

## Laboratorista (Futuro)

| ID | Historia | Criterio de aceptacion |
| -- | -------- | ---------------------- |
| US-020 | Como laboratorista, quiero ver las muestras tomadas para ingresar los resultados del analisis. | Puedo filtrar muestras por fuente, fecha y tipo de analisis. |
| US-021 | Como laboratorista, quiero cargar el resultado de un analisis fisicoquimico o microbiologico para que quede registrado en la DB. | Puedo ingresar valores numericos o textuales segun el tipo de analisis. |
