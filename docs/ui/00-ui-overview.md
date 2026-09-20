# UI Overview

## Principios de Diseno

La interfaz de **Agua** esta disenada para operarios que trabajan en
plantas industriales, muchas veces al aire libre con sol directo. Los
principios clave son:

1. **Alto contraste**: colores que se lean bien con sol y brillo.
2. **Botones grandes**: area de toque minima de 48x48dp, botones de
   ancho completo para facilitar el uso con guantes o una mano.
3. **Poca informacion por pantalla**: evitar sobrecarga cognitiva.
4. **Feedback inmediato**: confirmaciones visuales claras de cada accion.

## Dispositivos Soportados

| Dispositivo | Uso principal | Estrategia |
| ----------- | ------------- | ---------- |
| **Celular** | Operario en planta, exterior. | Layout vertical, botones apilados full width. |
| **Tablet** | Laboratorista en estacion de trabajo, supervisor en planta. | Layout adaptativo, dos columnas cuando hay espacio. |

### Adaptacion a Tablet

En tablet, la pantalla tiene mas ancho aprovechable. La adaptacion
mantiene la misma navegacion vertical pero agrega **vistas de dos
columnas** para pantallas de lista + detalle:

```
┌─────────────────────────────────────────────┐
│  Home                                       │
│  ┌──────────────────┐  ┌──────────────────┐ │
│  │ Pendientes (3)   │  │ Realizadas (12)  │ │
│  └──────────────────┘  └──────────────────┘ │
│  ┌──────────────────┐  ┌──────────────────┐ │
│  │ Vencidas (1)     │  │ [Nueva Muestra]  │ │
│  └──────────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────┘
```

```
┌─────────────────────────────────────────────┐
│  Historial                                  │
│  ┌──────────────────┐  ┌──────────────────┐ │
│  │ Filtros          │  │ Detalle muestra  │ │
│  │ Lista de items   │  │ seleccionada     │ │
│  │                  │  │                  │ │
│  └──────────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────┘
```

**Regla**: en celulares, todo es una columna. En tablets (>600dp ancho),
las pantallas de lista muestran detalle a la derecha cuando hay espacio.

### Breakpoints

| Breakpoint | Ancho | Comportamiento |
| ---------- | ----- | ------------e |
| `mobile` | < 600dp | Una columna, botones full width apilados. |
| `tablet` | >= 600dp | Dos columnas en listas, botones mantienen estilo apilado pero con ancho maximo. |

## Navegacion

La navegacion usa **botones de ancho completo apilados verticalmente**,
uno debajo del otro. No hay bottom tabs ni drawer lateral.

```
┌──────────────────────────┐
│                          │
│   [  Nueva Muestra   ]   │
│                          │
│   [  Mis Muestras    ]   │
│                          │
│   [  Alertas (3)     ]   │
│                          │
│   [  Mi Cuenta       ]   │
│                          │
└──────────────────────────┘
```

**Razon**: en exterior con sol, los botones grandes y apilados son mas
faciles de identificar y tocar que iconos pequenos en una barra inferior.
En tablet, los botones mantienen el estilo apilado pero con un ancho
maximo de ~400dp centrados en pantalla para no desperdiciar espacio.

## Tema: Claro y Oscuro

| Tema | Uso principal | Contraste |
| ---- | ------------- | --------- |
| **Claro** | Exterior, exterior con sol, ambientes bien iluminados. | Alto contraste, fondos claros. |
| **Oscuro** | Interior, ambientes con poca luz, reduccion de fatiga visual. | Alto contraste, fondos oscuros. |

Ambos temas mantienen los mismos estandares de legibilidad. El usuario
puede cambiar entre ellos desde "Mi Cuenta".

## Colores

Ver `03-design-system.md` para la paleta completa.

## Pantallas Principales (MVP)

| Pantalla | Funcion |
| -------- | ------- |
| Login | Inicio de sesion. |
| Home | Resumen del dia: pendientes, realizadas, vencidas. Botones de accion rapida. |
| Nueva Muestra | Formulario de registro con seleccion de fuente y tipo de analisis. |
| Historial | Lista de muestras con filtros. |
| Alertas | Lista de alertas pendientes y vencidas. |
| Mi Cuenta | Perfil, cambio de contrasena, tema claro/oscuro. |
| Admin - Config | Gestion de grifos, pozos, tipos de analisis, frecuencias. |
| Admin - Usuarios | Gestion de usuarios del tenant. |
