# Domain

Define los conceptos principales del negocio: entidades, relaciones y la
informacion que representa cada una.

---

## Documentos

| Archivo | Contenido |
| ------- | --------- |
| `domain-model.md` | Modelo conceptual: conceptos, relaciones e invariantes. |
| `entities.md` | Descripcion detallada de cada entidad y sus atributos. |
| `data-model.md` | Esquema fisico SQLite3: tablas, columnas, indices y relaciones. |

## Orden de lectura

1. `domain-model.md` — vision general del dominio y sus relaciones.
2. `entities.md` — detalle de cada entidad con sus atributos.
3. `data-model.md` — esquema SQL listo para implementar.

## Consejos

- El modelo de dominio debe entenderse sin leer codigo.
- Cuando cambia una entidad, actualiza el dominio ANTES del schema.
