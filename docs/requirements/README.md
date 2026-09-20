# Requirements

Define que debe hacer el sistema: reglas de negocio, funcionalidades,
restricciones y comportamientos esperados.

---

## Documentos

| Archivo | Contenido |
| ------- | --------- |
| `business-rules.md` | Reglas que gobiernan el comportamiento del sistema. |
| `functional-requirements.md` | Funcionalidades que debe ofrecer la aplicacion, vinculadas a reglas. |
| `non-functional-requirements.md` | Calidad, rendimiento, seguridad, disponibilidad. |
| `authentication.md` | Modelo de usuarios, autenticacion y autorizacion. |
| `user-stories.md` | Necesidades expresadas desde la perspectiva del usuario. |

## Orden de lectura

1. `business-rules.md` — las reglas inquebrantables del dominio.
2. `functional-requirements.md` — que hace el sistema, regla por regla.
3. `authentication.md` — como se autentican y autorizan los usuarios.
4. `user-stories.md` — la voz del usuario en cada rol.
5. `non-functional-requirements.md` — restricciones tecnicas y de calidad.

## Consejos

- Las reglas de negocio son la fuente de verdad para los casos de prueba.
- Cada requisito funcional deberia poder rastrearse hasta su implementacion.
