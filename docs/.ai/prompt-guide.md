# Prompt Guide

## Para Desarrollar Nuevas Funcionalidades

```
Contexto: estamos desarrollando Agua, un SaaS de control de calidad
del agua para empresas de alimentos. Stack: FastAPI + SQLModel
(backend) y Flutter (mobile). DB SQLite3 por tenant.

Tarea: [descripcion concreta de lo que se necesita].

Restricciones:
- Seguir coding standards en docs/.ai/coding-standards.md
- Incluir tests
- Usar Convventional Commits
- Referenciar la spec/requisito correspondiente si existe
```

## Para Escribir Tests

```
Contexto: [modulo que se esta testeando].

Escribe tests para [funcionalidad especifica]:
- Unit tests usando pytest (backend) o flutter test (mobile)
- Usar fixtures existentes o crear nuevos en conftest.py
- Cubrir: happy path, error cases, edge cases
- Referenciar el caso de prueba TC-XXX si existe
```

## Para Revisar Codigo

```
Revisa este codigo contra:
1. docs/.ai/coding-standards.md
2. docs/.ai/definition-of-done.md
3. La spec/requisito correspondiente

Lista: problemas encontrados, sugerencias de mejoration, y si cumple
con el Definition of Done.
```

## Para Documentar

```
Actualiza la documentacion en docs/ para reflejar [cambio].

Archivos afectados: [lista de archivos que cambiaron]
Nuevo comportamiento: [descripcion]
Regla de negocio afectada: [BN-XXX si aplica]
```
