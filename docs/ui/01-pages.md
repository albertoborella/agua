# Paginas

> Cada pantalla se adapta a celulares (una columna) y tablets (dos
> columnas cuando hay listas). Ver `00-ui-overview.md` para breakpoints.

## 1. Login

**Objetivo**: que el usuario ingrese sus credenciales.

**Elementos**:
- Campo usuario (texto, full width).
- Campo contrasena (password, full width).
- Boton "Ingresar" (full width, primario).
- Mensaje de error (si aplica).

**Estados**:
- Default: campos vacios.
- Cargando: boton deshabilitado con spinner.
- Error: mensaje rojo debajo de los campos.

**Tablet**: formulario centrado con ancho maximo de 400dp.

---

## 2. Home (Pantalla Principal)

**Objetivo**: mostrar el estado del dia del operario.

**Elementos**:
- Saludo con nombre del operario.
- Resumen del dia:
  - **Pendientes**:数量 con indicador naranja.
  - **Realizadas**: cantidad con indicador verde.
  - **Vencidas**: cantidad con indicador rojo.
- Botones de accion:
  - "Nueva Muestra" (primario, full width).
  - "Ver Historial" (secundario, full width).
  - "Alertas" (secundario, full width, con badge de cantidad).

**Estados**:
- Sin pendientes: "Todo al dia" con icono de check verde.
- Con pendientes: lista resumida.
- Sin conexion: banner amarillo "Sin conexion - modo offline".

**Tablet**: las 4 tarjetas de resumen se muestran en grid 2x2. Los botones
de accion se apilan a la izquierda con ancho maximo de 400dp.

---

## 3. Nueva Muestra

**Objetivo**: registrar una toma de muestra.

**Elementos**:
- Tipo de analisis: select full width con los tipos configurados.
- Fuente de agua:
  - Para Cloro: el sistema muestra la fuente sugerida (aleatoria) con
    boton "Cambiar fuente".
  - Para otros tipos: select con fuentes activas.
- Boton "Confirmar Toma" (primario, full width).
- Boton "Cancelar" (secundario, full width).

**Flujo**:
1. Seleccionar tipo de analisis.
2. Seleccionar fuente (o aceptar la sugerida para cloro).
3. Confirmar.
4. Feedback: "Muestra registrada" con resumen.
5. Volver al Home.

**Estados**:
- Default: campos sin seleccionar.
- Fuente sugerida (cloro): muestra nombre y ubicacion de la fuente.
- Cargando: boton deshabilitado con spinner.
- Exito: mensaje verde con check.
- Error: mensaje rojo.

---

## 4. Historial

**Objetivo**: consultar muestras pasadas.

**Elementos**:
- Filtros (full width):
  - Fuente (select).
  - Tipo de analisis (select).
  - Rango de fechas (date picker).
- Lista de resultados con:
  - Fecha y hora.
  - Fuente (nombre + tipo).
  - Tipo de analisis.
  - Operario.
- Paginacion.

**Estados**:
- Sin resultados: "No hay muestras para los filtros seleccionados".
- Cargando: skeleton loading.

**Tablet**: layout de dos columnas — filtros + lista a la izquierda,
detalle de la muestra seleccionada a la derecha.

---

## 5. Alertas

**Objetivo**: ver notificaciones pendientes.

**Elementos**:
- Lista de alertas con:
  - Tipo de analisis.
  - Fuente.
  - Fecha/hora esperada.
  - Estado (pendiente, vencida, programada) con color.
- Tap en una alerta la marca como leida.

**Estados**:
- Sin alertas: "No tenes alertas pendientes".
- Con alertas: lista agrupada por estado.

---

## 6. Mi Cuenta

**Objetivo**: gestionar perfil y configuracion personal.

**Elementos**:
- Nombre de usuario.
- Email.
- Rol.
- Boton "Cambiar Contrasena" (full width).
- Switch "Tema Oscuro" (full width).
- Boton "Cerrar Sesion" (full width, peligro/rojo).

---

## 7. Admin - Configuracion

**Objetivo**: administrar la planta.

**Elementos** (accesible solo para ADMIN):
- Botones de seccion (full width, apilados):
  - "Grifos y Pozos".
  - "Tipos de Analisis".
  - "Frecuencias de Muestreo".
- Cada boton lleva a una sub-pantalla de gestion (CRUD).

---

## 8. Admin - Usuarios

**Objetivo**: gestionar usuarios del tenant.

**Elementos**:
- Boton "Nuevo Usuario" (primario, full width).
- Lista de usuarios con:
  - Username.
  - Email.
  - Rol (badge).
  - Estado (activo/inactivo).
- Tap en un usuario: opciones editar, desactivar, restablecer contrasena.
