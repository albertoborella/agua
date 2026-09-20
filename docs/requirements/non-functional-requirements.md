# Requisitos No Funcionales

## 1. Rendimiento

| Codigo | Requisito |
| ------ | --------- |
| RNF-001 | La app movil debe cargar la pantalla principal en menos de 2 segundos con conectividad normal. |
| RNF-002 | La sincronizacion de muestras offline debe completarse en menos de 30 segundos para un lote de hasta 50 muestras. |
| RNF-003 | El backend debe soportar al menos 100 usuarios concurrentes por instancia de tenant. |

## 2. Disponibilidad y Resiliencia

| Codigo | Requisito |
| ------ | --------- |
| RNF-010 | La app movil debe funcionar completamente sin conexion: registro de muestras, consulta de historial local y visualizacion de alertas cacheadas. |
| RNF-011 | Los datos offline deben persistirse en almacenamiento local seguro hasta la sincronizacion. |
| RNF-012 | Si la sincronizacion falla, el sistema debe reintentar automaticamente con backoff exponencial. |

## 3. Seguridad

| Codigo | Requisito |
| ------ | --------- |
| RNF-020 | Las contrasenas deben almacenarse hasheadas con bcrypt o argon2, nunca en texto plano. |
| RNF-021 | La comunicacion entre la app movil y el backend debe usar HTTPS (TLS 1.2+). |
| RNF-022 | Cada tenant debe tener datos aislados; una consulta nunca debe retornar datos de otro tenant. |
| RNF-023 | Los tokens de sesion deben expirar tras 30 minutos de inactividad (configurable). |

## 4. Escalabilidad

| Codigo | Requisito |
| ------ | --------- |
| RNF-030 | La arquitectura multi-tenant debe permitir agregar nuevas empresas sin modificar codigo. |
| RNF-031 | SQLite3 es la DB inicial; el diseno debe permitir migracion a PostgreSQL o similar si el volumen lo requiere. |

## 5. Usabilidad

| Codigo | Requisito |
| ------ | --------- |
| RNF-040 | El flujo de registro de una muestra debe completarse en no mas de 4 pasos (seleccionar fuente, tipo de analisis, confirmar). |
| RNF-041 | La interfaz del operario debe ser usable con una sola mano en un celular. |
| RNF-042 | Los mensajes de error y alertas deben ser comprensibles para usuarios no tecnicos. |

## 6. Mantenibilidad

| Codigo | Requisito |
| ------ | --------- |
| RNF-050 | El codigo debe seguir convenciones de estilo del lenguaje (Python PEP 8, Dart effective Dart). |
| RNF-051 | Toda funcionalidad debe tener al menos una prueba automatizada asociada. |
| RNF-052 | Los endpoints API deben estar documentados con OpenAPI/Swagger. |
