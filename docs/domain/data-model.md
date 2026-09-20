# Modelo de Datos (SQLite3)

## Diagrama de Tablas

```
tenants
  ├── plants
  │     ├── water_sources
  │     │     └── sampling_frequencies
  │     └── (samples via tenant_id)
  ├── users
  ├── sample_records
  │     ├── water_source_id -> water_sources
  │     ├── analysis_type_id -> analysis_types
  │     └── operator_id -> users
  └── alerts
        ├── water_source_id -> water_sources
        ├── analysis_type_id -> analysis_types
        └── user_id -> users

analysis_types (catalogo global)
```

## Esquema

### tenants

```sql
CREATE TABLE tenants (
    id          TEXT PRIMARY KEY,  -- UUID
    nombre      TEXT NOT NULL,
    activa      INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);
```

### plants

```sql
CREATE TABLE plants (
    id          TEXT PRIMARY KEY,
    tenant_id   TEXT NOT NULL REFERENCES tenants(id),
    nombre      TEXT NOT NULL,
    direccion   TEXT,
    activa      INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_plants_tenant ON plants(tenant_id);
```

### water_sources

```sql
CREATE TABLE water_sources (
    id          TEXT PRIMARY KEY,
    planta_id   TEXT NOT NULL REFERENCES plants(id),
    tipo        TEXT NOT NULL CHECK(tipo IN ('GRIFO', 'POZO')),
    nombre      TEXT NOT NULL,
    ubicacion   TEXT,
    activa      INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_water_sources_planta ON water_sources(planta_id);
CREATE INDEX idx_water_sources_tipo ON water_sources(tipo);
```

### users

```sql
CREATE TABLE users (
    id              TEXT PRIMARY KEY,
    tenant_id       TEXT NOT NULL REFERENCES tenants(id),
    username        TEXT NOT NULL,
    email           TEXT NOT NULL,
    password_hash   TEXT NOT NULL,
    rol             TEXT NOT NULL CHECK(rol IN ('ADMIN', 'OPERARIO', 'LABORATORISTA')),
    activo          INTEGER NOT NULL DEFAULT 1,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(tenant_id, username),
    UNIQUE(tenant_id, email)
);

CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_rol ON users(rol);
```

### analysis_types (catalogo)

```sql
CREATE TABLE analysis_types (
    id                      TEXT PRIMARY KEY,
    codigo                  TEXT NOT NULL UNIQUE,
    nombre                  TEXT NOT NULL,
    requiere_descripcion    INTEGER NOT NULL DEFAULT 0
);

-- Datos iniciales
INSERT INTO analysis_types (id, codigo, nombre, requiere_descripcion) VALUES
    ('at-cloro', 'CLORO', 'Nivel de Cloro', 0),
    ('at-fq',    'FQ',    'Analisis Fisicoquimico', 0),
    ('at-mb',    'MB',    'Analisis Microbiologico', 0),
    ('at-otro',  'OTRO',  'Otro Analisis', 1);
```

### sampling_frequencies

```sql
CREATE TABLE sampling_frequencies (
    id                  TEXT PRIMARY KEY,
    fuente_id           TEXT NOT NULL REFERENCES water_sources(id),
    tipo_analisis_id    TEXT NOT NULL REFERENCES analysis_types(id),
    frecuencia          TEXT NOT NULL CHECK(frecuencia IN ('DIARIA', 'SEMANAL', 'QUINCENAL', 'MENSUAL')),
    dias_semana         TEXT,  -- JSON: [1,3,5] para lunes/miercoles/viernes
    hora_esperada       TEXT,  -- HH:MM
    activa              INTEGER NOT NULL DEFAULT 1,
    created_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_sampling_freq_fuente ON sampling_frequencies(fuente_id);
CREATE INDEX idx_sampling_freq_tipo ON sampling_frequencies(tipo_analisis_id);
```

### sample_records

```sql
CREATE TABLE sample_records (
    id                  TEXT PRIMARY KEY,
    tenant_id           TEXT NOT NULL REFERENCES tenants(id),
    fuente_id           TEXT NOT NULL REFERENCES water_sources(id),
    tipo_analisis_id    TEXT NOT NULL REFERENCES analysis_types(id),
    descripcion_otro    TEXT,
    operario_id         TEXT NOT NULL REFERENCES users(id),
    fecha               TEXT NOT NULL,  -- YYYY-MM-DD
    hora                TEXT NOT NULL,  -- HH:MM:SS
    sincronizada        INTEGER NOT NULL DEFAULT 0,
    created_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_samples_tenant ON sample_records(tenant_id);
CREATE INDEX idx_samples_fuente ON sample_records(fuente_id);
CREATE INDEX idx_samples_operario ON sample_records(operario_id);
CREATE INDEX idx_samples_fecha ON sample_records(fecha);
CREATE INDEX idx_samples_tipo ON sample_records(tipo_analisis_id);
```

### alerts

```sql
CREATE TABLE alerts (
    id                  TEXT PRIMARY KEY,
    tenant_id           TEXT NOT NULL REFERENCES tenants(id),
    usuario_id          TEXT NOT NULL REFERENCES users(id),
    tipo                TEXT NOT NULL CHECK(tipo IN ('PENDIENTE', 'VENCIDA', 'PROGRAMADA')),
    fuente_id           TEXT NOT NULL REFERENCES water_sources(id),
    tipo_analisis_id    TEXT NOT NULL REFERENCES analysis_types(id),
    fecha_esperada      TEXT NOT NULL,
    leida               INTEGER NOT NULL DEFAULT 0,
    created_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_alerts_tenant ON alerts(tenant_id);
CREATE INDEX idx_alerts_usuario ON alerts(usuario_id);
CREATE INDEX idx_alerts_fecha ON alerts(fecha_esperada);
CREATE INDEX idx_alerts_tipo ON alerts(tipo);
```

## Notas de Implementacion

- Los IDs son UUIDs generados en la app (SQLite3 no tiene `gen_random_uuid()`
  nativo; se genera en Python con `uuid.uuid4()`).
- Las fechas se almacenan como texto ISO 8601 (`YYYY-MM-DD` y `HH:MM:SS`).
- Los booleanos se representan como `INTEGER` (0/1) por compatibilidad con
  SQLite3.
- El campo `sincronizada` en `sample_records` controla la sincronizacion
  offline-online.
- La columna `tenant_id` en `sample_records` y `alerts` permite consultas
  eficientes por tenant sin subqueries.
