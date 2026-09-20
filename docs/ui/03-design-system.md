# Design System

## Paleta de Colores

### Tema Claro

Diseñada para maxima legibilidad al aire libre con sol directo.
Colores de alto contraste, sin tonos pastel que se pierdan con brillo.

| Nombre | Hex | Uso |
| ------ | --- | --- |
| **Primary** | `#0D47A1` | Azul oscuro. Botones primarios, headers, links. |
| **Primary Variant** | `#1565C0` | Azul medio. Estados hover, pressed. |
| **Secondary** | `#00695C` | Verde azulado. Indicadores positivos, checkmarks. |
| **Background** | `#FAFAFA` | Gris muy claro. Fondo general. |
| **Surface** | `#FFFFFF` | Blanco. Tarjetas, modales, campos de formulario. |
| **Error** | `#B71C1C` | Rojo oscuro. Errores, alertas vencidas, botones de peligro. |
| **On Primary** | `#FFFFFF` | Texto sobre color primario. |
| **On Background** | `#212121` | Texto principal sobre fondo claro. |
| **On Surface** | `#212121` | Texto sobre superficies. |
| **Outline** | `#BDBDBD` | Bordes de campos, divisores. |
| **Warning** | `#E65100` | Naranja oscuro. Alertas pendientes, advertencias. |
| **Success** | `#1B5E20` | Verde oscuro. Confirmaciones, estados OK. |

### Tema Oscuro

Mismos estandares de contraste que el claro, pero con fondos oscuros
para reducir fatiga visual en ambientes con poca luz.

| Nombre | Hex | Uso |
| ------ | --- | --- |
| **Primary** | `#90CAF9` | Azul claro. Botones primarios, headers. |
| **Primary Variant** | `#64B5F6` | Azul medio. Estados hover, pressed. |
| **Secondary** | `#80CBC4` | Verde aguamarina. Indicadores positivos. |
| **Background** | `#121212` | Negro suave. Fondo general. |
| **Surface** | `#1E1E1E` | Gris muy oscuro. Tarjetas, modales. |
| **Error** | `#EF5350` | Rojo. Errores, alertas vencidas. |
| **On Primary** | `#000000` | Texto sobre color primario. |
| **On Background** | `#E0E0E0` | Texto principal sobre fondo oscuro. |
| **On Surface** | `#E0E0E0` | Texto sobre superficies oscuras. |
| **Outline** | `#424242` | Bordes de campos, divisores. |
| **Warning** | `#FF9800` | Naranja. Alertas pendientes. |
| **Success** | `#66BB6A` | Verde. Confirmaciones. |

---

## Tipografia

| Elemento | Font Size | Font Weight | Uso |
| -------- | --------- | ----------- | --- |
| H1 | 28sp | Bold | Titulos de pantalla. |
| H2 | 22sp | Semi-bold | Subtitulos de seccion. |
| H3 | 18sp | Semi-bold | Titulos de tarjeta. |
| Body | 16sp | Regular | Texto principal. |
| Caption | 14sp | Regular | Descripciones, metadata. |
| Button | 18sp | Semi-bold | Texto de botones. |
| Small | 12sp | Regular | Badges, notas al pie. |

**Fuente**: sistema (Roboto en Android, San Francisco en iOS) para
máximo rendimiento y natividad.

---

## Espaciado

| Token | Valor | Uso |
| ----- | ----- | --- |
| `xs` | 4dp | Separacion entre elementos muy cercanos. |
| `sm` | 8dp | Padding interno de tarjetas pequenas. |
| `md` | 12dp | Separacion entre tarjetas. |
| `lg` | 16dp | Padding interno de tarjetas grandes, campos de formulario. |
| `xl` | 24dp | Separacion entre secciones. |
| `xxl` | 32dp | Margen superior de pantallas. |

---

## Bordes

| Elemento | Radio |
| -------- | ----- |
| Botones | 12dp |
| Tarjetas | 12dp |
| Campos de formulario | 8dp |
| Badges | 10dp (mitad del tamaño) |

---

## Sombras (Tema Claro)

| Elemento | Elevacion |
| -------- | --------- |
| Tarjetas | 2dp |
| Botones (pressed) | 4dp |
| Modales | 8dp |

**Tema oscuro**: las sombras se reemplazan por bordes sutiles de color
`#333333` porque las sombras no son visibles sobre fondos oscuros.

---

## Accesibilidad

- **Contraste minimo**: 4.5:1 para texto normal, 3:1 para texto grande
  (cumple WCAG AA).
- **Area de toque minima**: 48x48dp para todos los elementos interactivos.
- **Texto escalable**: todos los tamanos usan `sp` para respetar la
  configuracion de tamano de texto del dispositivo.
- **Iconos con label**: ningun icono se muestra sin texto alternativo.

---

## Adaptacion a Tablet

### Breakpoints

| Nombre | Ancho minimo | Comportamiento |
| ------ | ------------ | -------------- |
| `mobile` | 0dp | Una columna, botones full width. |
| `tablet` | 600dp | Dos columnas en listas, botones con ancho maximo. |

### Cambios en Tablet

| Elemento | Mobile | Tablet |
| -------- | ------ | ------ |
| Botones de navegacion | Full width | Ancho maximo 400dp, centrados. |
| Tarjetas de resumen (Home) | Stack vertical | Grid 2x2. |
| Historial | Lista full width | Lista (izq) + Detalle (der). |
| Alertas | Lista full width | Lista (izq) + Detalle (der). |
| Formularios | Full width | Ancho maximo 400dp, centrados. |
| Admin - Config | Lista full width | Lista (izq) + Formulario (der). |
| Admin - Usuarios | Lista full width | Lista (izq) + Formulario (der). |

### Espaciado Tablet

| Token | Mobile | Tablet |
| ----- | ------ | ------ |
| `page-padding` | 16dp | 32dp |
| `card-gap` | 12dp | 16dp |
| `max-content-width` | 100% | 480dp (por columna) |
