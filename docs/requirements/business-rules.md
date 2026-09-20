# Reglas de Negocio

## 1. Autenticacion y Gestion de Usuarios

| Codigo | Regla |
| ------ | ----- |
| BN-001 | El **primer administrador** del sistema se registra mediante un script de inicializacion (similar a `createsuperuser` de Django). No existe registro por UI para este primer usuario. |
| BN-002 | El administrador registrado por script tiene permisos totales sobre la configuracion de la planta: usuarios, grifos, pozos y frecuencias. |
| BN-003 | El administrador **crea y asigna** usuario y contrasena a cada empleado segun su rol (Administrador, Operario, Laboratorista). |
| BN-004 | Los empleados pueden cambiar su contrasena a traves de un link enviado por el administrador o generado por el sistema. |
| BN-005 | Cada usuario se autentica con usuario y contrasena. Las sesiones tienen un tiempo limite de inactividad configurable. |

## 2. Configuracion de la Planta

| Codigo | Regla |
| ------ | ----- |
| BN-010 | El administrador puede cargar, editar y desactivar **grifos** de la planta. Cada grifo tiene: nombre, ubicacion y estado (activo/inactivo). |
| BN-011 | El administrador puede cargar, editar y desactivar **pozos** de la planta. Cada pozo tiene: nombre, ubicacion y estado (activo/inactivo). |
| BN-012 | Solo las fuentes activas aparecen disponibles para el operario al registrar una muestra. |
| BN-013 | El administrador define **frecuencias de muestreo** por tipo de analisis y fuente. |
| BN-014 | El administrador configura la **lista de tipos de analisis** disponibles (ej: Cloro, FQ, MB, y otros que necesite). |

## 3. Registro de Muestras

| Codigo | Regla |
| ------ | ----- |
| BN-020 | El operario registra una **toma de muestra** seleccionando: fuente (grifo o pozo) y tipo de analisis. |
| BN-021 | Los tipos de analisis son los configurados por el administrador (ej: Cloro, FQ, MB, y otros). El operario selecciona de esa lista. |
| BN-021a | Para **Cloro**, el sistema selecciona **aleatoriamente** un grifo/pozo de los activos. El operario puede cambiarlo manualmente si es necesario. |
| BN-022 | Cada muestra registra obligatoriamente: fuente, tipo de analisis, **fecha**, **hora** y el **operario** que la tomo. |
| BN-023 | El registro de fecha y hora es automatico al momento de confirmar la toma; el operario no lo edita manualmente. |
| BN-024 | Para **Nivel de Cloro** se permiten multiples tomas al mismo grifo/pozo en un mismo dia, ya que la frecuencia puede ser diaria con varias mediciones. |
| BN-025 | Para **FQ** y **MB** la frecuencia esta predefinida por el administrador. El sistema genera alertas cuando la fecha programada se acerca o vence. |
| BN-026 | Si no hay conectividad, la muestra se almacena localmente y se sincroniza cuando haya red. |

## 4. Alertas

| Codigo | Regla |
| ------ | ----- |
| BN-030 | El sistema genera una alerta cuando una medicion de **cloro** esta pendiente para el dia actual. |
| BN-031 | El sistema genera una alerta cuando una medicion de **FQ** o **MB** esta programada para la fecha. |
| BN-032 | El sistema genera una alerta de vencimiento cuando una medicion programada no se registro en el dia/hora esperado. |
| BN-033 | Las alertas son visibles para el operario en la pantalla principal de la app movil, **solo las de su planta**. |
