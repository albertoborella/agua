# Template: Delta Spec

> Copia este archivo como `docs/specs/nombre-del-cambio.md` y completa
> las secciones antes de implementar.

---

# [Nombre del Cambio]

## Metadata

| Campo | Valor |
| ----- | ----- |
| **Nombre** | [nombre-descriptivo] |
| **Fecha** | [YYYY-MM-DD] |
| **Autor** | [nombre] |
| **Estado** | Borrador / Aprobada / Implementada |

## Propuesta

**Que**: [descripcion concisa del cambio]

**Por que**: [problema que resuelve o valor que agrega]

**Alcance**: [que entra y que no]

## Requisitos

### Requisitos Funcionales

| Codigo | Requisito | Fortaleza |
| ------ | --------- | --------- |
| RF-XXX | [requisito 1] | MUST |
| RF-XXX | [requisito 2] | SHOULD |

### Reglas de Negocio Afectadas

| Codigo | Regla |
| ------ | ----- |
| BN-XXX | [regla existente afectada] |

### Escenarios

**Escenario 1: [nombre del escenario]**
- **Dado**: [precondicion]
- **Cuando**: [accion]
- **Entonces**: [resultado esperado]

**Escenario 2: [nombre del escenario]**
- **Dado**: [precondicion]
- **Cuando**: [accion]
- **Entonces**: [resultado esperado]

## Diseno Tecnico

### Endpoint(s)

| Metodo | Path | Descripcion |
| ------ | ---- | ----------- |
| POST | `/v1/...` | [descripcion] |

### Modelo de Datos

```sql
-- CAMBIOS EN EL SCHEMA
```

### Flujo

```
[pseudocodigo o diagrama de secuencia]
```

## Testing

| Caso de prueba | Que valida |
| -------------- | ---------- |
| TC-XXX | [descripcion] |

## No-Objetivos

- [cosa que explicitamente no se hace en este cambio]
- [otra cosa que no se hace]
