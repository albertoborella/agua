# Entidades

## Tenant (Empresa)

Representa la empresa de alimentos cliente del sistema.

| Atributo | Tipo | Descripcion |
| -------- | ---- | ----------- |
| `id` | UUID | Identificador unico. |
| `nombre` | Text | Nombre de la empresa. |
| `activa` | Boolean | Si la empresa esta activa en el sistema. |
| `created_at` | Timestamp | Fecha de creacion. |

## Planta

Unidad operativa dentro de una empresa.

| Atributo | Tipo | Descripcion |
| -------- | ---- | ----------- |
| `id` | UUID | Identificador unico. |
| `tenant_id` | FK -> Tenant | Empresa propietaria. |
| `nombre` | Text | Nombre de la planta. |
| `direccion` | Text | Direccion fisica (opcional). |
| `activa` | Boolean | Si la planta esta operativa. |

## Fuente de Agua

Punto fisico de donde se toma la muestra.

| Atributo | Tipo | Descripcion |
| -------- | ---- | ----------- |
| `id` | UUID | Identificador unico. |
| `planta_id` | FK -> Planta | Planta a la que pertenece. |
| `tipo` | Enum | `GRIFO` o `POZO`. |
| `nombre` | Text | Nombre identificatorio (ej: "Grifo Sector A"). |
| `ubicacion` | Text | Ubicacion fisica dentro de la planta. |
| `activa` | Boolean | Si la fuente esta disponible para muestreo. |

## Usuario

Persona que interactua con el sistema.

| Atributo | Tipo | Descripcion |
| -------- | ---- | ----------- |
| `id` | UUID | Identificador unico. |
| `tenant_id` | FK -> Tenant | Empresa a la que pertenece. |
| `username` | Text | Nombre de usuario (unico por tenant). |
| `email` | Text | Correo electronico. |
| `password_hash` | Text | Contrasena hasheada (bcrypt/argon2). |
| `rol` | Enum | `ADMIN`, `OPERARIO`, `LABORATORISTA`. |
| `activo` | Boolean | Si el usuario puede iniciar sesion. |
| `created_at` | Timestamp | Fecha de creacion. |

## Tipo de Analisis

Catalogo de tipos de control de agua.

| Atributo | Tipo | Descripcion |
| -------- | ---- | ----------- |
| `id` | UUID | Identificador unico. |
| `codigo` | Text | Codigo corto: `CLORO`, `FQ`, `MB`, `OTRO`. |
| `nombre` | Text | Nombre descriptivo. |
| `requiere_descripcion` | Boolean | Si es `true`, se debe proveer texto libre (para "Otro"). |

## Frecuencia de Muestreo

Regla que define periodicidad de analisis por fuente.

| Atributo | Tipo | Descripcion |
| -------- | ---- | ----------- |
| `id` | UUID | Identificador unico. |
| `fuente_id` | FK -> Fuente de Agua | Fuente aplicable. |
| `tipo_analisis_id` | FK -> Tipo de Analisis | Tipo de analisis. |
| `frecuencia` | Enum | `DIARIA`, `SEMANAL`, `QUINCENAL`, `MENSUAL`. |
| `dias_semana` | JSON | Dias especificos si es semanal (ej: [1,3,5]). |
| `hora_esperada` | Time | Hora aproximada de muestreo (para alertas). |
| `activa` | Boolean | Si la frecuencia esta vigente. |

## Muestra

Registro de una toma de agua realizada.

| Atributo | Tipo | Descripcion |
| -------- | ---- | ----------- |
| `id` | UUID | Identificador unico. |
| `tenant_id` | FK -> Tenant | Empresa (para aislamiento). |
| `fuente_id` | FK -> Fuente de Agua | De donde se tomo. |
| `tipo_analisis_id` | FK -> Tipo de Analisis | Que se analizo. |
| `descripcion_otro` | Text | Descripcion si tipo es "Otro" (opcional). |
| `operario_id` | FK -> Usuario | Quien la tomo. |
| `fecha` | Date | Fecha de la toma (automatica). |
| `hora` | Time | Hora de la toma (automatica). |
| `sincronizada` | Boolean | Si ya se sincronizo con el servidor. |
| `created_at` | Timestamp | Timestamp completo de registro. |

## Alerta

Notificacion generada por el sistema.

| Atributo | Tipo | Descripcion |
| -------- | ---- | ----------- |
| `id` | UUID | Identificador unico. |
| `tenant_id` | FK -> Tenant | Empresa. |
| `usuario_id` | FK -> Usuario | A quien se le notifica. |
| `tipo` | Enum | `PENDIENTE`, `VENCIDA`, `PROGRAMADA`. |
| `fuente_id` | FK -> Fuente de Agua | Fuente relacionada. |
| `tipo_analisis_id` | FK -> Tipo de Analisis | Analisis pendiente. |
| `fecha_esperada` | Date | Fecha en que debia hacerse. |
| `leida` | Boolean | Si el usuario ya la vio. |
| `created_at` | Timestamp | Cuando se genero. |
