# Preguntas Abiertas

## Pendientes de Decision

| ID | Pregunta | Impacto | Estado |
| -- | -------- | ------- | ------ |
| OQ-001 | ¿Como se maneja la sincronizacion offline cuando dos operarios registran la misma fuente en el mismo momento? | Bajo (MVP: ultimo en sincronizar gana, sin conflictos de datos criticos). | Resuelto: no hay conflicto, cada muestra es un registro independiente. |
| OQ-002 | ¿Se requiere backup automatico de las DBs de cada tenant? | Medio. | Pendiente. |
| OQ-003 | ¿Cada empresa tendra su propio servidor o todas compartiran la misma instancia? | Alto (multi-tenant por directorio vs por servidor). | Pendiente. |
| OQ-004 | ¿El script createsuperadmin se ejecuta una vez por deployment o una vez por tenant? | Medio. | Pendiente. |
| OQ-005 | ¿Se necesita algun tipo de auditoria de cambios (log de quién modificó qué)? | Bajo para MVP. | Pendiente. |

## Resueltas

| ID | Pregunta | Resolucion |
| -- | -------- | ---------- |
| OQ-R01 | ¿Analisis "Otro" con texto libre o lista configurable? | Lista configurable por el admin. |
| OQ-R02 | ¿Selección aleatoria de grifos para cloro? | Si, el sistema sugiere aleatoriamente, el operario puede cambiar. |
| OQ-R03 | ¿Alertas globales o por planta? | Solo por planta del operario. |
