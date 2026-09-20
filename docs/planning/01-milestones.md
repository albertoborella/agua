# Hitos

## M1: MVP

### M1.1 - Backend Base

**Criterio de aceptacion**:
- FastAPI levanta con `/health` retorna 200.
- Auth JWT funciona (login, refresh, change-password).
- Multi-tenant: dos tenants no comparten datos.
- Script `createsuperadmin` crea el primer usuario.

### M1.2 - Configuracion CRUD

**Criterio de aceptacion**:
- Admin puede crear, editar, desactivar grifos y pozos.
- Admin puede configurar tipos de analisis.
- Admin puede configurar frecuencias de muestreo.
- Solo fuentes activas aparecen para el operario.

### M1.3 - Registro de Muestras

**Criterio de aceptacion**:
- Operario puede registrar muestra con fuente, tipo y timestamp automatico.
- Cloro permite multiples tomas por dia en la misma fuente.
- Muestra se asocia al operario logueado.

### M1.4 - Alertas

**Criterio de aceptacion**:
- Sistema genera alertas pendientes, vencidas y programadas.
- Alertas son visibles solo para la planta del operario.
- Marcar como leida funciona.

### M1.5 - Mobile: Login y Home

**Criterio de aceptacion**:
- Login con credenciales.
- Home muestra resumen del dia (pendientes, realizadas, vencidas).
- Navegacion con botones full width apilados.

### M1.6 - Mobile: Nueva Muestra

**Criterio de aceptacion**:
- Select de tipo de analisis funcional.
- Para cloro: fuente sugerida aleatoriamente, cambio manual posible.
- Confirmacion registra la muestra.

### M1.7 - Mobile: Historial y Alertas

**Criterio de aceptacion**:
- Historial con filtros por fuente, tipo y fecha.
- Alertas con lista y marcado como leida.

### M1.8 - Offline-First

**Criterio de aceptacion**:
- Muestras se guardan localmente sin conexion.
- Sincronizacion automatica al recuperar red.
- Banner de estado offline visible.

### M1.9 - Tests Backend

**Criterio de aceptacion**:
- Cobertura >80% en services.
- Todos los endpoints con al menos un test de integracion.
- Tests pasan en CI.

### M1.10 - Tests Mobile

**Criterio de aceptacion**:
- Cobertura >70% en features principales.
- Widgets testeados.
- Tests pasan en CI.
