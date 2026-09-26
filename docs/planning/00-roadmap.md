# Roadmap

## Fase 1: MVP (Baseline)

**Objetivo**: app movil funcional para registro de muestras offline-first.

| Hito | Descripcion | Estado |
| ---- | ----------- | ------ |
| M1.1 | Backend: proyecto FastAPI con auth JWT, multi-tenant. | Completado |
| M1.2 | Backend: CRUD de configuracion (grifos, pozos, tipos, frecuencias). | Completado |
| M1.3 | Backend: registro de muestras y consulta. | Completado |
| M1.4 | Backend: generacion de alertas. | Parcial — lectura y marcado como leida; **nada genera alertas** (ver M1.11) |
| M1.5 | Mobile: pantalla de login y home. | Completado |
| M1.6 | Mobile: registro de muestras con seleccion aleatoria (cloro). | Completado |
| M1.7 | Mobile: historial y alertas. | Completado — historial sin paginacion (ver M1.12) |
| M1.8 | Mobile: modo offline y sincronizacion. | Pendiente |
| M1.9 | Tests: backend unit + integracion. | Pendiente — sin tests |
| M1.10 | Tests: mobile unit + widget. | Parcial — `mobile/test/app_boot_test.dart` con 3 tests de boot + restauracion de sesion. Sin tests de pantallas |
| M1.11 | Backend: generacion automatica de alertas. | Pendiente — scheduler que crea alertas desde `sampling_frequencies` |
| M1.12 | Mobile: refresco de token automatico (401 -> refresh). | Pendiente — una sesion guardada con token vencido hoy da 401 |

## Fase 2: Lab Module (Post-MVP)

**Objetivo**: modulo de laboratorio para ingreso de resultados.

| Hito | Descripcion | Estado |
| ---- | ----------- | ------ |
| M2.1 | Backend: endpoints para resultados de analisis. | Pendiente |
| M2.2 | Mobile/PC: pantalla de laboratorio para carga de resultados. | Pendiente |
| M2.3 | Reportes de cumplimiento por periodo. | Pendiente |

## Fase 3: Escalabilidad (Futuro)

| Hito | Descripcion | Estado |
| ---- | ----------- | ------ |
| M3.1 | Exportacion CSV/PDF. | Pendiente |
| M3.2 | Dashboard de compliance. | Pendiente |
| M3.3 | Integraciones con sistemas externos. | Pendiente |
