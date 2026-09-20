# Testing

Estrategia de pruebas y casos de prueba del proyecto.

---

## Documentos

| Archivo | Contenido |
| ------- | --------- |
| `00-strategy.md` | Estrategia de pruebas: niveles, herramientas, cobertura, ejecucion. |
| `01-test-cases.md` | Casos de prueba derivados de reglas de negocio y casos de uso. |

## Resumen de Cobertura

| Modulo | Casos de prueba | Estado |
| ------ | --------------- | ------ |
| Autenticacion | TC-AUTH-001 a 011 | Definidos |
| Configuracion | TC-ADM-001 a 011 | Definidos |
| Registro de Muestras | TC-SAM-001 a 012 | Definidos |
| Alertas | TC-ALT-001 a 007 | Definidos |
| Multi-Tenant | TC-TEN-001 a 003 | Definidos |

**Total: 44 casos de prueba.**

## Orden de lectura

1. `00-strategy.md` — como se testea el proyecto.
2. `01-test-cases.md` — los casos concretos caso por caso.

## Consejos

- Cada regla de negocio de `docs/requirements/` tiene su caso de prueba.
- En SDD, los tests se escriben contra la spec, no contra la implementacion.
- Los casos se ejecutan como parte del pipeline de CI/CD.
