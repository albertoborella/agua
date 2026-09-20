# Caso de Uso: Alertas

## UC-ALT-001: Ver Alertas Pendientes

**Actor**: Operario.

**Precondicion**: El operario esta logueado. Existen frecuencias de
muestreo configuradas.

**Flujo principal**:

1. El operario accede a la pantalla principal.
2. El sistema muestra las alertas pendientes de **su planta**:
   - **Pendientes**: mediciones que deberian hacerse hoy y aun no se
     registraron.
   - **Programadas**: mediciones de FQ o MB con fecha futura proxima.
   - **Vencidas**: mediciones que ya pasaron la fecha/hora esperada sin
     registrarse.
3. Cada alerta muestra: tipo de analisis, fuente, fecha/hora esperada y
   estado.

**Postcondicion**: El operario conoce que mediciones debe realizar.

---

## UC-ALT-002: Marcar Alerta como Leida

**Actor**: Operario.

**Precondicion**: Existe una alerta pendiente visible.

**Flujo principal**:

1. El operario visualiza una alerta en la lista.
2. Al acceder a la alerta o registrar la muestra correspondiente, el
   sistema marca la alerta como "leida".
3. La alerta leida se oculta de la vista principal o pasa a una seccion
   de "historial de alertas".

**Postcondicion**: La alerta queda registrada como vista por el operario.

---

## UC-ALT-003: Generacion Automatica de Alertas

**Actor**: Sistema (automatico).

**Precondicion**: Existen frecuencias de muestreo activas.

**Flujo principal**:

1. El sistema evalua periodicamente (ej: cada hora) las frecuencias
   configuradas.
2. Para cada frecuencia activa, el sistema verifica:
   - Si la fecha actual coincide con la programacion (diaria, semanal, etc.).
   - Si no existe una muestra registrada para esa fuente + tipo + fecha.
3. Si falta la muestra, el sistema genera una alerta:
   - Tipo `PENDIENTE` si es para el dia actual.
   - Tipo `VENCIDA` si ya paso la fecha/hora esperada.
   - Tipo `PROGRAMADA` si es para una fecha futura proxima.
4. La alerta se asocia al tenant, la fuente, el tipo de analisis y se
   asigna a los operarios de esa planta.

**Flujos alternativos**:

- **2a. La frecuencia es de Cloro**: el sistema solo genera alerta si
  no hay ninguna muestra de cloro registrada en la fuente para el dia
  actual (ya que se permiten multiples tomas).

**Postcondicion**: Las alertas quedan visibles para los operarios
correspondientes.

---

## UC-ALT-004: Alerta por Cloro Pendiente del Dia

**Actor**: Sistema (automatico) / Operario.

**Precondicion**: Existen grifos o pozos activos con frecuencia de cloro.

**Flujo principal**:

1. Al iniciar sesion, el operario ve en la pantalla principal si hay
   mediciones de cloro pendientes para el dia.
2. El sistema muestra: "Tenes X mediciones de cloro pendientes para hoy."
3. Si el operario ya registro al menos una muestra de cloro en el dia
   para esa fuente, la alerta se marca como cumplida.

**Postcondicion**: El operario es informado de sus mediciones de cloro
del dia.
