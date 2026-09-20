# Visión del Proyecto

## Problema

En las empresas de alimentos, el control de calidad del agua es una actividad
rutinaria que se ejecuta varias veces al día. Incluye la medición de cloro
nivel en grifos (una o más veces diarias, en grifos seleccionados
aleatoriamente), análisis fisicoquímicos y microbiológicos con frecuencias
programadas, y la toma de muestras desde grifos y pozos de la planta
industrial.

Estos controles hoy se realizan de forma manual: el operario toma nota en
papel, los datos se transcriben después, y no hay una forma centralizada de
saber qué se mide, cuándo se mide y si se cumplieron las frecuencias
establecidas. Esto genera:

- **Riesgo de incumplimiento**: si el operario no mide o no registra, la
  empresa no lo sabe hasta que es demasiado tarde.
- **Pérdida de trazabilidad**: los registros en papel se dañan, se pierden o
  son difíciles de consultar.
- **Falta de alertas**: no hay un mecanismo que avise cuando una medición
  está pendiente o vencida.
- **Doble carga de trabajo**: el laboratorio recibe los datos por otro canal
  y debe reingresarlos en su sistema.

## Solución

**Agua** es un sistema SaaS (Software as a Service) que digitaliza el control
de calidad del agua en plantas de producción de alimentos. Permite a las
empresas configurar sus fuentes de agua (grifos y pozos), definir frecuencias
de muestreo y registrar las tomas de muestras en tiempo real desde un celular.

El sistema opera en dos frentes:

1. **Celular (MVP)**: el operario registra al momento la toma de muestra —
   qué fuente, qué análisis, cuándo y quién lo hizo.
2. **Computadora de laboratorio (futuro)**: el laboratorista ingresa los
   resultados analizados, completando el ciclo de control.

## Usuarios

| Rol | Quién es | Qué hace en el sistema |
| ----- | ---------------------- | -------------------------------------- |
| **Administrador** | Responsable de calidad o jefe de planta | Configura la planta: grifos, pozos, frecuencias de muestreo, y gestiona usuarios y roles. |
| **Operario** | Personal de planta que toma muestras | Registra tomas de muestras desde el celular en el momento de realizarlas. |
| **Laboratorista** | Personal del laboratorio interno o externo | Ingresa resultados de análisis en la estación de trabajo (futuro). |

## Propuesta de Valor

- **Cumplimiento garantizado**: alertas automáticas cuando una medición está
  pendiente o vencida.
- **Trazabilidad completa**: cada muestra queda registrada con fuente, fecha,
  hora y operario — sin papeles.
- **Configuración por planta**: cada empresa adapta el sistema a sus grifos,
  pozos y frecuencias reales.
- **Escalable**: multi-tenant, cada empresa tiene su propia instancia
  independiente.

## Principios

1. **Mobile-first**: la experiencia principal es el celular del operario.
   Simple, rápido, sin fricción.
2. **Cumplimiento como feature**: no es un módulo extra, es el corazón del
   sistema.
3. **Evolución incremental**: arrancamos con registro de muestras, agregamos
   laboratorio después — sin romper nada.
4. **Datos que hablan**: la información registrada debe poder consultarse,
   filtrarse y reportarse.
