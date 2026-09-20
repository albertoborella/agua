# Caso de Uso: Registro de Muestras

## UC-SAM-001: Registrar Muestra de Cloro (con seleccion aleatoria)

**Actor**: Operario.

**Precondicion**: El operario esta logueado. Existen grifos o pozos activos
configurados.

**Flujo principal**:

1. El operario accede a "Nueva muestra" desde la pantalla principal.
2. El sistema detecta que el tipo de analisis es "Cloro" (o el operario
   lo selecciona).
3. El sistema selecciona **aleatoriamente** un grifo o pozo de los
   disponibles y lo muestra al operario.
4. El operario puede:
   - **Aceptar el grifo sugerido**: presiona "Confirmar toma".
   - **Cambiar el grifo**: presiona "Cambiar fuente", selecciona otra de
     la lista, y presiona "Confirmar toma".
5. El sistema registra la muestra con:
   - Fuente seleccionada (la aleatoria o la cambiada).
   - Tipo de analisis: Cloro.
   - Fecha y hora automaticas.
   - Operario logueado.
6. El sistema muestra "Muestra registrada correctamente" con un resumen.

**Flujos alternativos**:

- **4a. No hay fuentes activas**: "No hay grifos ni pozos disponibles.
  Contacte al administrador."
- **5a. Sin conexion**: el sistema almacena la muestra localmente y muestra
  "Muestra guardada offline. Se sincronizara cuando haya conexion."

**Postcondicion**: La muestra queda registrada en la base de datos (local
o remota).

---

## UC-SAM-002: Registrar Muestra de FQ o MB

**Actor**: Operario.

**Precondicion**: El operario esta logueado. Existen fuentes activas.

**Flujo principal**:

1. El operario accede a "Nueva muestra".
2. El operario selecciona el tipo de analisis: "FQ" o "MB".
3. El sistema muestra la lista de fuentes activas (grifos y pozos).
4. El operario selecciona la fuente de donde tomo la muestra.
5. El operario presiona "Confirmar toma".
6. El sistema registra la muestra con:
   - Fuente seleccionada.
   - Tipo de analisis: FQ o MB.
   - Fecha y hora automaticas.
   - Operario logueado.
7. El sistema muestra "Muestra registrada correctamente".

**Flujos alternativos**:

- **3a. Sin fuentes activas**: "No hay fuentes disponibles. Contacte al
  administrador."
- **6a. Sin conexion**: se almacena offline.

**Postcondicion**: La muestra queda registrada.

---

## UC-SAM-003: Registrar Muestra de Otro Tipo

**Actor**: Operario.

**Precondicion**: El operario esta logueado. Existen tipos de analisis
configurados por el administrador.

**Flujo principal**:

1. El operario accede a "Nueva muestra".
2. El operario selecciona un tipo de analisis de la lista configurada
   por el administrador (que no sea Cloro, FQ ni MB).
3. El sistema muestra la lista de fuentes activas.
4. El operario selecciona la fuente.
5. El operario presiona "Confirmar toma".
6. El sistema registra la muestra.
7. El sistema muestra "Muestra registrada correctamente".

**Postcondicion**: La muestra queda registrada.

---

## UC-SAM-004: Ver Muestras del Dia

**Actor**: Operario.

**Precondicion**: El operario esta logueado.

**Flujo principal**:

1. El operario accede a la pantalla principal.
2. El sistema muestra un resumen del dia:
   - **Realizadas**: lista de muestras ya registradas hoy con hora, fuente
     y tipo de analisis.
   - **Pendientes**: mediciones que deverian hacerse hoy segun frecuencias
     configuradas.
   - **Vencidas**: mediciones que ya vencieron sin registrarse.

**Postcondicion**: El operario tiene visibilidad completa de su estado
del dia.

---

## UC-SAM-005: Ver Historial de Muestras

**Actor**: Operario.

**Precondicion**: El operario esta logueado.

**Flujo principal**:

1. El operario accede a "Historial".
2. El sistema muestra las muestras del operario con filtros disponibles:
   - Por fuente (grifo o pozo especifico).
   - Por tipo de analisis.
   - Por rango de fechas.
3. El operario aplica los filtros que necesite.
4. El sistema muestra los resultados paginados.

**Postcondicion**: El operario puede consultar cualquier muestra pasada.
