# Caso de Uso: Administracion y Configuracion

## UC-ADM-001: Crear Planta

**Actor**: Administrador.

**Precondicion**: El administrador esta logueado.

**Flujo principal**:

1. El administrador accede a "Configuracion" > "Plantas" > "Nueva planta".
2. El sistema muestra un formulario con: nombre, direccion (opcional).
3. El administrador completa los datos y presiona "Crear".
4. El sistema valida y guarda la planta.
5. El sistema muestra "Planta creada correctamente".

**Postcondicion**: La planta queda disponible para configurar grifos y
pozos.

---

## UC-ADM-002: Gestionar Grifos

**Actor**: Administrador.

**Precondicion**: Existe al menos una planta configurada.

**Flujo principal**:

1. El administrador accede a "Configuracion" > "Grifos".
2. El sistema muestra la lista de grifos de la planta seleccionada.
3. El administrador puede:
   - **Agregar**: presiona "Nuevo grifo", ingresa nombre, ubicacion, y
     confirma.
   - **Editar**: selecciona un grifo, modifica datos, guarda.
   - **Desactivar**: selecciona un grifo, presiona "Desactivar", confirma.

**Flujos alternativos**:

- **3a. Desactivar grifo con muestras**: el sistema advierte "Este grifo
  tiene X muestras registradas. Solo se desactivara, no se eliminara."

**Postcondicion**: Los grifos activos aparecen disponibles para el
operario al registrar muestras.

---

## UC-ADM-003: Gestionar Pozos

**Actor**: Administrador.

**Precondicion**: Existe al menos una planta configurada.

**Flujo principal**: Igual a UC-ADM-002 pero para pozos.

---

## UC-ADM-004: Configurar Tipos de Analisis

**Actor**: Administrador.

**Precondicion**: El administrador esta logueado.

**Flujo principal**:

1. El administrador accede a "Configuracion" > "Tipos de analisis".
2. El sistema muestra la lista de tipos configurados (ej: Cloro, FQ, MB).
3. El administrador puede:
   - **Agregar**: presiona "Nuevo tipo", ingresa nombre y codigo, confirma.
   - **Editar**: modifica nombre o codigo de un tipo existente.
   - **Desactivar**: oculta el tipo sin eliminarlo.

**Postcondicion**: Los tipos activos aparecen en el select del operario
al registrar muestras.

---

## UC-ADM-005: Configurar Frecuencias de Muestreo

**Actor**: Administrador.

**Precondicion**: Existen fuentes de agua y tipos de analisis configurados.

**Flujo principal**:

1. El administrador accede a "Configuracion" > "Frecuencias".
2. El sistema muestra las frecuencias existentes.
3. El administrador presiona "Nueva frecuencia".
4. El sistema muestra un formulario:
   - Seleccionar fuente (grifo o pozo).
   - Seleccionar tipo de analisis.
   - Seleccionar frecuencia (diaria, semanal, quincenal, mensual).
   - Si es semanal: seleccionar dias de la semana.
   - Hora esperada de muestreo (opcional, para alertas).
5. El administrador completa y confirma.
6. El sistema guarda y muestra "Frecuencia configurada".

**Postcondicion**: El sistema genera alertas automaticas segun esta
frecuencia.

---

## UC-ADM-006: Gestionar Usuarios

**Actor**: Administrador.

**Precondicion**: El administrador esta logueado.

**Flujo principal**:

1. El administrador accede a "Usuarios".
2. El sistema muestra la lista de usuarios del tenant.
3. El administrador puede:
   - **Crear**: presiona "Nuevo usuario", ingresa username, email,
     contrasena inicial, rol, y confirma.
   - **Editar**: selecciona un usuario, modifica datos, guarda.
   - **Desactivar**: selecciona un usuario, presiona "Desactivar", confirma.
   - **Restablecer contrasena**: selecciona un usuario, ingresa nueva
     contrasena, confirma.

**Flujos alternativos**:

- **3a. Username duplicado**: "Ya existe un usuario con ese nombre."
- **3b. Email duplicado**: "Ya existe un usuario con ese email."

**Postcondicion**: Los usuarios creados pueden iniciar sesion con sus
credenciales.
