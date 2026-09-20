# Alcance

## Que incluye esta version (MVP)

### Configuracion de la planta

- Carga de **grifos** de la planta industrial (nombre, ubicacion, estado
  activo/inactivo).
- Carga de **pozos** de la planta industrial (nombre, ubicacion, estado
  activo/inactivo).
- Definicion de **frecuencias de muestreo** por tipo de analisis
  (fisicoquimico, microbiologico) y fuente (grifo, pozo, ambos).
- Gestion de **usuarios** con roles: Administrador, Operario, Laboratorista.

### Registro de muestras (celular)

- El **operario** selecciona la fuente de agua (grifo o pozo).
- El sistema le indica que tipo de analisis corresponde segun la
  frecuencia configurada.
- El operario confirma la toma de muestra y el sistema registra:
  fuente, tipo de analisis, fecha/hora y operario.
- El registro se almacena localmente si no hay conectividad y se sincroniza
  cuando hay red.

### Alertas y notificaciones

- Aviso al operario cuando una medicion de **cloro** esta pendiente para el
  dia actual.
- Aviso cuando una medicion de analisis fisicoquimico o microbiologico esta
  programada para la fecha.
- Aviso cuando una medicion vencio sin registrarse.

### Panel de consulta (celular)

- Vista del dia: que mediciones se hicieron, cuales estan pendientes, cuales
  vencieron.
- Historial de muestras por fuente y por periodo.

## Que NO incluye esta version

| Fuera de alcance | Por que |
| ---------------- | ------- |
| Modulo de laboratorio (ingreso de resultados) | Se desarrolla despues del MVP como fase separada. |
| Analisis estadisticos o tendencias | Requiere datos acumulados; se agrega cuando haya volumen. |
| Integracion con sistemas externos (SAP, etc.) | El MVP es autonomo; integraciones van en roadmap futuro. |
| Multi-idioma | Arrancamos en espanol; internacionalizacion es futuro. |
| Gestion de proveedores de laboratorio externo | Futuro. |
| Certificados o constancias de cumplimiento | Futuro, requiere definicion de formato oficial. |

## Supuestos

- Cada empresa tiene al menos un Administr tecnico que puede configurar
  el sistema.
- Los operarios tienen acceso a un celular con conectividad (aunque sea
  intermitente).
- Las frecuencias de muestreo son definidas por la empresa segun sus
  necesidades y la normativa vigente.
- El control de cloro es una medicion rapida que se registra en el momento;
  no requiere configuracion de frecuencia avanzada.
