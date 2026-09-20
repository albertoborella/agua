# Definition of Done

Una tarea esta **completada** cuando cumple TODOS los siguientes criterios:

## Codigo

- [ ] El codigo compila sin errores.
- [ ] El codigo pasa el linter sin warnings nuevos.
- [ ] El codigo sigue los coding standards del proyecto.
- [ ] No hay codigo duplicado no justificado.

## Testing

- [ ] Tiene al menos un test que cubre la funcionalidad.
- [ ] Todos los tests existentes pasan.
- [ ] La cobertura no disminuye respecto al estado anterior.

## Documentacion

- [ ] Si agrega un endpoint, esta documentado en `docs/architecture/01-api-design.md`.
- [ ] Si agrega una regla de negocio, esta en `docs/requirements/business-rules.md`.
- [ ] Si agrega un caso de uso, esta en `docs/use-cases/`.
- [ ] Los READMEs de las carpetas afectadas estan actualizados si aplica.

## Commit

- [ ] El commit sigue Convventional Commits.
- [ ] El mensaje describe QUE se hizo y POR QUE (si no es obvio).
- [ ] No hay archivos sensibles (passwords, keys) en el commit.

## Revisión

- [ ] El PR esta abierto contra `main`.
- [ ] La descripcion del PR explica el cambio.
- [ ] Todos los checks de CI pasan.
