# Workflow

## Flujo de Desarrollo

```
1. Crear branch desde main
   git checkout -b feat/nombre-descriptivo

2. Desarrollar con tests
   - Escribir test primero (TDD recomendado)
   - Implementar funcionalidad
   - Verificar que pasa

3. Commit con convencion
   git commit -m "feat(auth): add JWT login endpoint"

4. Push y PR
   git push origin feat/nombre-descriptivo
   Abrir Pull Request contra main.

5. Review
   - self-review del diff
   - Verificar tests pasan
   - Verificar docs actualizadas si aplica

6. Merge
   Squash merge o merge commit (sin fast-forward).
```

## Ramas

| Tipo | Patron | Ejemplo |
| ---- | ------ | ------- |
| Feature | `feat/descripcion` | `feat/jwt-login` |
| Fix | `fix/descripcion` | `fix/offline-sync` |
| Docs | `docs/descripcion` | `docs/api-design` |
| Refactor | `refactor/descripcion` | `refactor/auth-service` |

## Commits (Conventional Commits)

```
<tipo>(<scope>): <descripcion corta>

[opcional: cuerpo con contexto]

[opcional: footer con refs]
```

**Tipos permitidos**:
- `feat`: nueva funcionalidad.
- `fix`: correccion de bug.
- `docs`: documentacion.
- `style`: formato (no afecta logica).
- `refactor`: reestructuracion sin cambio de comportamiento.
- `test`: agregar o modificar tests.
- `chore`: tareas de mantenimiento (deps, CI, etc.).

**Scopes del proyecto**:
- `auth`: autenticacion y autorizacion.
- `admin`: configuracion de planta y usuarios.
- `samples`: registro de muestras.
- `alerts`: sistema de alertas.
- `mobile`: app Flutter.
- `backend`: general del backend.

**Ejemplos**:
```
feat(samples): add chlorine random tap selection
fix(alerts): fix pending alerts not showing for current day
docs(api): add endpoint documentation for samples
test(auth): add integration tests for login flow
```

## Pull Requests

- Titulo claro describiendo el cambio.
- Descripcion con contexto y motivacion.
- Tests que pasan.
- Docs actualizadas si aplica.
- Maximo ~400 lineas cambiadas (ideal).
