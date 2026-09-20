# Objetivos

## Objetivo General

Digitalizar el control de calidad del agua en plantas de producción de
alimentos, eliminando los registros en papel y garantizando el cumplimiento
de frecuencias de muestreo.

## Objetivos Específicos

### MVP (Versión 1)

| # | Objetivo | Métrica de éxito |
| - | -------- | ---------------- |
| O1 | Registrar tomas de muestras desde el celular en tiempo real. | 100% de las muestras del día se registran en el sistema (sin papel). |
| O2 | Configurar grifos y pozos por planta. | El administrador puede cargar, editar y desactivar fuentes de agua. |
| O3 | Definir frecuencias de muestreo para análisis fisicoquímicos y microbiológicos. | Las frecuencias se configuran por tipo de análisis y fuente. |
| O4 | Generar alertas cuando una medición está pendiente o vencida. | El operario recibe notificación antes de la fecha/hora de muestreo. |
| O5 | Identificar qué operario realizó cada toma de muestra. | Cada registro incluye el usuario que lo creó y laimestamp. |

### Futuro (Post-MVP)

| # | Objetivo | Contexto |
| - | -------- | -------- |
| O6 | Ingresa resultados de análisis desde una PC de laboratorio. | Módulo de laboratorio — se define después del MVP. |
| O7 | Generar reportes de cumplimiento por período. | Dashboard de compliance para supervisores y auditores. |
| O8 | Exportar datos en formatos estándar (CSV, PDF). | Integración con sistemas de gestión de calidad existentes. |

## Restricciones de Negocio

- Cada empresa de alimentos es un tenant independiente con su propia
  instancia.
- Los datos de una empresa nunca se mezclan con los de otra.
- El sistema debe funcionar con conectividad limitada (plantas industriales
  pueden tener señal intermitente).
- La configuración inicial es responsabilidad del rol Administrador.
