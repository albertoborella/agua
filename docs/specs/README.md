# Specs

Especificaciones SDD. Cada cambio del proyecto tiene su propia
especificacion (delta spec) con requisitos y escenarios.

---

## Estructura SDD

Cada cambio del proyecto sigue el ciclo SDD:

```
proposal -> spec -> design -> tasks -> apply -> verify -> archive
```

En esta carpeta se guardan las especificaciones (delta specs) con formato:

```
specs/<nombre-del-cambio>.md
```

Cada spec contiene requisitos con su fortaleza (MUST / SHALL / SHOULD) y
escenarios verificables.

## Documentos

| Archivo | Contenido |
| ------- | --------- |
| `README.md` | Este indice y guia del ciclo SDD. |
| `TEMPLATE.md` | Plantilla para escribir una spec nueva. |
| `<cambio>.md` | Spec de un cambio concreto (se agrega con cada change). |

## Consejos

- La spec se escribe ANTES del codigo: es el contrato del cambio.
- Si un requisito no se puede verificar, no es un requisito.
- Usar la plantilla `TEMPLATE.md` como punto de partida.
