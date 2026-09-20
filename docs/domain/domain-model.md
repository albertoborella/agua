# Modelo de Dominio

## Conceptos Principales

El dominio de **Agua** gira en torno al control de calidad del agua en
plantas de produccion de alimentos. Los conceptos clave son:

### Empresa (Tenant)

Cada empresa de alimentos es una instancia independiente del sistema.
Encapsula toda la configuracion, usuarios y datos de muestreo. No hay
mezcla de datos entre empresas.

### Planta

Una empresa puede tener una o mas plantas industriales. Cada planta tiene
sus propios grifos, pozos y frecuencias de muestreo. En la version MVP
trabajamos con una planta por empresa.

### Fuente de Agua

Punto fisico del cual se toma la muestra. Puede ser:

- **Grifo** — punto de agua de la red interna de la planta.
- **Pozo** — punto de extraccion de agua subterranea.

Cada fuente tiene nombre, ubicacion fisica y estado (activo/inactivo).
Solo las fuentes activas estan disponibles para muestreo.

### Analisis

Tipo de control que se realiza sobre el agua. Los tipos son:

- **Nivel de Cloro** — medicion rapida, puede ser varias veces al dia.
- **Analisis Fisicoquimico (FQ)** — analisis de laboratorio con frecuencia
  programada.
- **Analisis Microbiologico (MB)** — analisis de laboratorio con frecuencia
  programada.
- **Otro** — analisis no estandarizado, requiere descripcion libre.

### Muestra

Unidad minima de registro. Representa el acto fisico de tomar agua de una
fuente para analizarla. Cada muestra captura:

- Que fuente se uso.
- Que analisis se realizo.
- Cuando se tomo (fecha y hora automaticas).
- Quien la tomo (operario logueado).

### Frecuencia de Muestreo

Regla definida por el administrador que establece con que periodicidad
deben tomarse muestras para un tipo de analisis en una fuente especifica.
El sistema usa estas frecuencias para generar alertas.

### Alerta

Notificacion generada automaticamente cuando:

- Una medicion de cloro esta pendiente para el dia actual.
- Una medicion de FQ o MB esta programada para la fecha.
- Una medicion vencio sin registrarse.

---

## Relaciones

```
Empresa (Tenant)
  └── Planta
        ├── Fuente de Agresa (Grifo | Pozo)
        │     └── Frecuencia de Muestreo
        │           ├── Tipo de Analisis
        │           └── Periodicidad
        ├── Usuario (Admin | Operario | Laboratorista)
        └── Muestra
              ├── Fuente de Agua
              ├── Tipo de Analisis
              ├── Fecha/Hora
              └── Operario que la tomo
```

## Invariantes del Dominio

1. Una Muestra siempre pertenece a una sola Fuente de Agua.
2. Una Muestra siempre tiene un Tipo de Analisis.
3. Una Muestra siempre esta asociada al Operario que la tomo.
4. La Fecha/Hora de la Muestra es inmutable una vez registrada.
5. Solo las Fuentes activas pueden ser seleccionadas para una nueva Muestra.
6. Un Operario puede registrar multiples Muestras del mismo tipo en la misma
   Fuente en un mismo dia (especialmente para Cloro).
