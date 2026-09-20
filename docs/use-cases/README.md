# Use Cases

Define las interacciones entre los actores y el sistema para lograr un
objetivo concreto.

---

## Casos de Uso por Modulo

| Archivo | Contenido |
| ------- | --------- |
| `auth.md` | Inicio de sesion, cambio y restablecimiento de contrasena. |
| `admin-config.md` | Gestion de plantas, grifos, pozos, tipos de analisis, frecuencias y usuarios. |
| `sampling.md` | Registro de muestras: cloro (con seleccion aleatoria), FQ, MB y otros tipos. |
| `alerts.md` | Generacion automatica, visualizacion y marcado de alertas. |

## Actores

| Actor | Rol | Modulos que usa |
| ----- | --- | ---------------- |
| **Administrador** | Configura la planta y gestiona usuarios. | auth, admin-config |
| **Operario** | Toma muestras y consulta historial. | auth, sampling, alerts |
| **Laboratorista** | Ingresa resultados de analisis (futuro). | auth, lab (futuro) |
| **Sistema** | Genera alertas automaticamente. | alerts |

## Orden de lectura

1. `auth.md` — como ingresan los usuarios.
2. `admin-config.md` — como se configura el sistema.
3. `sampling.md` — el flujo central del operario.
4. `alerts.md` — como se generan y gestionan las alertas.

## Consejos

- Un caso de uso debe ser accionable: el lector entiende que hace el sistema.
- Los casos de uso alimentan los casos de prueba de `docs/testing/`.
