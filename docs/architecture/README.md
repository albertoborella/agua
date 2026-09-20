# Architecture

Define como se construye tecnicamente el sistema: tecnologias, componentes,
comunicacion entre servicios, seguridad y despliegue.

---

## Documentos

| Archivo | Contenido |
| ------- | --------- |
| `00-architecture.md` | Arquitectura general: stack, patrones, estructura del proyecto. |
| `01-api-design.md` | Diseno de la API REST: endpoints, esquemas, paginacion. |
| `02-security.md` | Modelo de seguridad: JWT, autorizacion, proteccion de datos. |
| `03-deployment.md` | Estrategia de despliegue: entornos, Docker, nginx, backup. |
| `04-decisions.md` | Indice de decisiones tecnicas (ADR). |

## Orden de lectura

1. `00-architecture.md` — vision general del sistema.
2. `01-api-design.md` — contratos de la API.
3. `02-security.md` — como se protege el sistema.
4. `03-deployment.md` — como se despliega.
5. `04-decisions.md` — por que se decidio asi.

## Consejos

- Los diagramas ayudan, pero tienen texto que los explica.
- Las decisiones tecnicas grandes van en `docs/decisions/` como ADR.
