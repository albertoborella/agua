# Componentes

## Componentes de Boton

### PrimaryButton

Boton principal de accion. Full width, fondo azul oscuro, texto blanco.

```
Uso: "Confirmar Toma", "Ingresar", "Crear".
Altura: 56dp.
Bordes: 12dp redondeados.
```

### SecondaryButton

Boton de accion secundaria. Full width, fondo transparente, borde azul,
texto azul.

```
Uso: "Cancelar", "Volver", "Ver Historial".
Altura: 56dp.
```

### DangerButton

Boton de accion destructiva. Full width, fondo rojo, texto blanco.

```
Uso: "Cerrar Sesion", "Desactivar".
Altura: 56dp.
```

---

## Componentes de Formulario

### TextField

Campo de texto. Full width, borde gris, fondo blanco (claro) o gris
oscuro (tema oscuro).

```
Uso: usuario, contrasena, nombre, ubicacion.
Altura: 56dp.
Padding horizontal: 16dp.
```

### SelectField

Campo de seleccion. Full width, muestra valor seleccionado con icono
de flecha abajo.

```
Uso: tipo de analisis, fuente de agua, rol.
Altura: 56dp.
```

### DatePicker

Selector de fecha. Full width, abre un modal de calendario.

```
Uso: rango de fechas en historial.
```

---

## Componentes de Tarjeta

### SummaryCard

Tarjeta de resumen en el Home. Muestra un numero grande y una
descripcion.

```
Uso: pendientes, realizadas, vencidas.
Fondo: blanco (claro) / gris oscuro (oscuro).
Bordes: 12dp.
Padding: 16dp.
```

### SampleCard

Tarjeta de una muestra en el historial.

```
Contenido: fecha, fuente, tipo de analisis, operario.
Bordes: 8dp.
Padding: 12dp.
```

### AlertCard

Tarjeta de una alerta. Incluye indicador de color por estado.

```
Estados:
- Pendiente: borde naranja.
- Vencida: borde rojo.
- Programada: borde azul.
```

---

## Componentes de Feedback

### SuccessBanner

Mensaje de confirmacion. Fondo verde claro, texto verde oscuro, icono
de check.

```
Uso: "Muestra registrada correctamente".
```

### ErrorBanner

Mensaje de error. Fondo rojo claro, texto rojo oscuro, icono de
exclamacion.

```
Uso: "Usuario o contrasena incorrectos".
```

### WarningBanner

Mensaje de advertencia. Fondo amarillo claro, texto amarillo oscuro.

```
Uso: "Sin conexion - modo offline".
```

### LoadingSpinner

Indicador de carga centrado en pantalla.

```
Uso: durante llamadas API o sincronizacion.
```

---

## Componentes de Navegacion

### NavButton

Boton de navegacion principal. Full width, apilado verticalmente,
fondo gris claro (claro) o gris oscuro (oscuro), texto grande.

```
Uso: botones del Home.
Altura: 64dp.
Font size: 18sp.
Font weight: semi-bold.
Icono opcional a la izquierda.
```

### Badge

Indicador numerico superpuesto en botones o tarjetas.

```
Uso: cantidad de alertas pendientes.
Fondo: rojo.
Texto: blanco, centrado.
Tamaño: 20dp.
```
