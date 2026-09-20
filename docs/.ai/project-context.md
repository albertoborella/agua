# Project Context

## Que es Agua

SaaS de control de calidad del agua para empresas de alimentos. Permite
registrar tomas de muestras desde un celular, configurar frecuencias de
muestreo y generar alertas automaticas.

## Stack

| Capa | Tecnologia |
| ---- | ---------- |
| Frontend | Flutter (iOS + Android) |
| Backend | Python 3.11+ / FastAPI |
| ORM | SQLModel |
| DB | SQLite3 (una por tenant) |
| Auth | JWT (access + refresh) |

## Repositorio

```
git@github.com:albertoborella/agua.git
```

## Estructura

```
agua/
├── backend/        ← FastAPI + SQLModel
├── mobile/         ← Flutter
├── docs/           ← Documentacion SDD
└── docker/         ← Configuracion de despliegue
```

## Actores

| Rol | Que hace |
| ---- | -------- |
| Administrador | Configura planta, usuarios, frecuencias. |
| Operario | Registra muestras desde el celular. |
| Laboratorista | Ingresa resultados (futuro). |

## Convenciones

- Commits: **Conventional Commits** (`feat:`, `fix:`, `docs:`, etc.).
- Ramas: feature branches desde `main`.
- Idioma del codigo: Python (PEP 8), Dart (effective Dart).
- Documentacion: espanol.
