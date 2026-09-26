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

**AppBar**: boton de ayuda (`help_outline`, tooltip "Instructivo") que abre la
pagina 9, antes del de configuracion y el de persona. Ojo: el boton de persona
y el de "Usuarios" apuntan a rutas que todavia no estan registradas y no abren.

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

---

## 9. Ayuda - Instructivo

**Objetivo**: manual de uso dentro de la app. Lleva a un usuario nuevo desde
cero hasta registrar su primera muestra.

**Acceso**: boton de ayuda (`help_outline`) en el AppBar del Home, antes del
de configuracion y el de persona. Ruta `/help`.

**Elementos**:
- Card "Atajo" arriba de todo, con los tres datos para entrar:
  - App: `http://localhost:8080` (el 5173 es otro proyecto).
  - ID de Empresa: `demo`.
  - Admin: `admin` / `Admin123!`.
- Secciones numeradas, cada una con titulo, bajada opcional y cuerpo:
  1. Levantar el sistema.
  2. Configurar el ID de Empresa.
  3. Entrar con un usuario.
  4. Usuarios de prueba (bloque de credenciales por rol).
  5. Registrar la primera muestra (pasos numerados).
  6. La regla del cloro.
  7. Consultar el historial.
  8. Revisar las alertas.
  9. Volver a los datos de prueba (bloque de comando monoespaciado).
- Seccion final "Limitaciones conocidas", en un recuadro ambar con icono de
  advertencia, para que no se lea como una lista de features.

**Reglas de contenido**: solo documenta comportamiento existente. El manual
incluye los limites conocidos a proposito —nada genera alertas solo, no hay
refresh de token, el historial no pagina, no hay logout, las rutas de
"Usuarios" y de cuenta no estan registradas, y las tarjetas del Home muestran
0 fijo— en vez de omitirlos.

**Estados**:
- Unico estado: es contenido estatico, no carga datos ni tiene estados de
  error ni de vacio.

**Tablet**: una sola columna, mismo contenido. El texto largo se copia de las
tarjetas de credenciales, del comando y de los bullets, no de la prosa.
