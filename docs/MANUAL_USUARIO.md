# Agua — Manual de Usuario

> **Sistema de Control de Calidad de Agua**  
> Versión 1.0 — Septiembre 2026

---

## 1. ¿Qué es Agua?

**Agua** es una aplicación para la gestión y control de la calidad de agua en empresas de saneamiento, cooperativas, municipios y laboratorios.

Permite:

- **Registrar tomas de muestra** en campo (operarios)
- **Programar frecuencias** de muestreo por fuente y tipo de análisis
- **Recibir alertas** cuando una muestra está pendiente o vencida
- **Consultar historial** completo con filtros
- **Administrar catálogos** (tipos de análisis, fuentes, plantas, usuarios) — solo administradores

---

## 2. Primeros pasos

### 2.1 Requisitos previos

- Navegador web moderno (Chrome, Firefox, Edge, Safari)
- Acceso a la URL donde esté desplegada la aplicación
- Credenciales proporcionadas por tu administrador

### 2.2 Acceso a la aplicación

1. Abre la URL de la aplicación (ej: `https://miempresa.agua.com` o `http://localhost:8080` en desarrollo)
2. Verás la pantalla de **Login**

### 2.3 Configuración inicial: ID de Empresa

> **Importante:** El "ID de Empresa" identifica a tu organización en el sistema (multi-tenant). **No se pide en el login**, se configura **una sola vez** en la pantalla de Configuración.

**Para probar la app con datos de demo:**
1. Tocá el ícono ⚙️ **Configuración** (arriba a la derecha)
2. En "ID de Empresa" escribí: `demo`
3. Tocá **Guardar**

**Cuando adquieras el sistema:**
Tu administrador te dará el ID de Empresa real (ej: `cooperativa-agua-azul`, `municipio-salto`, `lab-central`). Simplemente reemplaza `demo` por ese valor y guardá.

---

## 3. Roles de usuario

| Rol | Qué puede hacer | Quién lo usa |
|-----|-----------------|--------------|
| **ADMIN** | Todo: configurar catálogos, crear usuarios, ver todo | Gerentes, responsables de calidad, administradores TI |
| **OPERARIO** | Registrar muestras, ver historial, ver alertas | Personal de campo que toma las muestras |
| **LABORATORISTA** | Ver historial, consultar resultados, ver alertas | Personal de laboratorio que analiza las muestras |

> Solo el **ADMIN** ve la sección "Administración" en el Home.

---

## 4. Flujo diario del OPERARIO

### 4.1 Registrar una nueva muestra

1. En el **Home**, tocá **"Nueva Muestra"**
2. **Elegí el Tipo de Análisis** (Cloro, FQ, MB, OTRO, etc.)
3. **Elegí la Fuente de Agua:**
   - **Si es Cloro:** el sistema te propone una fuente al azar (regla de aleatoriedad). Si no es la correcta, tocá **"Cambiar fuente"** y elegí otra.
   - **Si es otro tipo:** se muestra el desplegable con todas las fuentes disponibles.
4. Tocá **"Confirmar Toma"**
5. Verás la confirmación con el resumen. Tocá **"Volver al inicio"**

### 4.2 La regla del Cloro (importante)

> El tipo de análisis con código **CLORO** se comporta distinto: al seleccionarlo, el sistema sortea una fuente al azar entre las disponibles. Esto obliga al operario a muestrear fuentes diferentes y evita que siempre elija la misma.

- Si la fuente propuesta no es la correcta → **"Cambiar fuente"**
- Cada vez que volvés a elegir **Cloro**, se sortea una nueva (la elección anterior se pierde)

---

## 5. Consultar el Historial

Desde el Home → **"Ver Historial"**

**Filtros disponibles:**
- **Fuente:** filtrar por una fuente específica
- **Tipo de análisis:** filtrar por Cloro, FQ, MB, etc.
- **Rango de fechas:** desde / hasta

**Botón "Limpiar filtros"** quita los tres filtros de una.

**Cada fila muestra:**
- Fecha y hora de la toma
- Fuente de agua
- Tipo de análisis
- Operario que la registró

---

## 6. Alertas

Desde el Home → **"Alertas"**

Las alertas aparecen agrupadas en tres pestañas:

| Pestaña | Qué significa |
|---------|---------------|
| **Vencidas** | La muestra debía tomarse y no se tomó en la fecha/hora esperada |
| **Pendientes** | La muestra está programada para hoy o próximamente |
| **Programadas** | Muestras futuras según las frecuencias configuradas |

**Acciones:**
- Tocá una alerta → se marca como **leída** y sale de la lista
- Las alertas se generan automáticamente según las **Frecuencias de Muestreo** configuradas por el ADMIN

---

## 7. Administración (solo ADMIN)

En el Home, sección **"Administración"**:

### 7.1 Usuarios
- **Crear:** nuevo usuario (username, email, password, rol)
- **Editar:** cambiar email, rol, activar/desactivar, resetear contraseña
- **Eliminar:** borrar usuario (no podés eliminarte a vos mismo)

### 7.2 Tipos de Análisis
Catálogo global de análisis que pueden elegir los operarios.
- **Código:** identificador único (ej: `CLORO`, `FQ`, `MB`)
- **Nombre:** nombre visible (ej: "Nivel de Cloro")
- **Requiere descripción:** si el operario debe escribir un detalle al registrar
- Los de **sistema** (CLORO, FQ, MB, OTRO) no se pueden eliminar

### 7.3 Fuentes de Agua
Puntos de toma de muestra asociados a una planta.
- **Tipo:** GRIFO, POZO, RIO, LAGUNA, OTRO (define el ícono)
- **Planta:** cada fuente pertenece a una planta
- **Ubicación:** descripción opcional (ej: "Planta baja - cocina")
- **Activa/Inactiva:** para habilitar o deshabilitar sin borrar historial

### 7.4 Frecuencias de Muestreo
Programación automática de cuándo se debe muestrear.
- **Fuente:** dónde se toma
- **Tipo de análisis:** qué se analiza
- **Frecuencia:** DIARIA, SEMANAL, QUINCENAL, MENSUAL, TRIMESTRAL, SEMESTRAL, ANUAL
- **Días de semana:** opcional (ej: "LUN,MIE,VIE" para semanal)
- **Hora esperada:** opcional (ej: "06:00")
- **Activa:** si está vigente o pausada

> Los cambios en catálogos son **inmediatos**: al volver a "Nueva Muestra" el operario ya ve los nuevos tipos y fuentes.

---

## 8. Gestión de sesión

- **La sesión se guarda en el navegador:** al cerrar la pestaña y volver a abrir, seguís logueado (mientras el token no expire — 30 min)
- **Cerrar sesión:** tocá tu avatar (arriba a la derecha) → **"Cerrar sesión"**
- **Cambiar contraseña:** en Configuración → **"Cambiar contraseña"**

---

## 9. Datos de prueba (solo desarrollo/demo)

| Usuario | Contraseña | Rol |
|---------|------------|-----|
| `admin` | `Admin123!` | ADMIN |
| `operario` | `Operario123!` | OPERARIO |
| `lab` | `Lab123!` | LABORATORISTA |

**ID de Empresa:** `demo`

> **Resetear datos de demo:** si ensuciaste los datos probando, ejecutá en el servidor:
> ```bash
> podman exec -w /app agua-backend python scripts/seed_demo.py --reset
> ```
> Esto borra todo y recrea los datos originales (74 muestras, 5 alertas, 3 usuarios).

---

## 10. Preguntas frecuentes

### "Me dice 'Primero configurá el ID de Empresa'"
→ Andá a ⚙️ Configuración, poné el ID (ej: `demo` o el que te dio tu admin) y guardá.

### "El botón Usuarios no me funciona"
→ Solo el **ADMIN** lo ve. Si sos operario o laboratorista, no tenés acceso.

### "Me salió 'Token inválido o expirado' al recargar"
→ La sesión expiró (30 min de inactividad). Volvé a loguearte.

### "No veo mis muestras en el historial"
→ Verificá los filtros (fuente, tipo, fecha). Tocá "Limpiar filtros".

### "Quiero agregar mi propia empresa"
1. Cambiá el ID de Empresa en Configuración por el que te asignaron
2. Logueate con tu usuario admin
3. En Administración → Usuarios, creá a tu equipo
4. En Administración → Fuentes, cargá tus plantas y fuentes
5. En Administración → Frecuencias, programá los muestreos

---

## 11. Soporte y contacto

- **Documentación técnica:** `/docs` (arquitectura, decisiones, specs)
- **Reportar bug / solicitar feature:** contactá a tu administrador o al equipo de desarrollo
- **Logs del backend:** `podman logs agua-backend`

---

## 12. Glosario rápido

| Término | Significado |
|---------|-------------|
| **Tenant / ID de Empresa** | Identificador único de tu organización en el sistema multi-inquilino |
| **Planta** | Agrupación lógica de fuentes (ej: "Planta Norte") |
| **Fuente** | Punto físico de toma (grifo, pozo, río, etc.) |
| **Tipo de análisis** | Qué parámetro se mide (Cloro, Fisicoquímico, Microbiológico) |
| **Frecuencia** | Cada cuánto se debe muestrear (diaria, semanal, mensual...) |
| **Muestra** | Registro de una toma realizada (fecha, hora, fuente, tipo, operario) |
| **Alerta** | Notificación automática cuando una muestra programada está pendiente o vencida |

---

*Fin del manual. Para dudas operativas, consultá a tu administrador del sistema.*