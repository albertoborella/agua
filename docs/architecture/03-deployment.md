# Despliegue

## 1. Entornos

| Entorno | Proposito | Backend | DB |
| ------- | --------- | ------- | -- |
| **Local** | Desarrollo individual | `uvicorn` en localhost:8000 | SQLite3 archivo local |
| **Local (contenedor)** | Desarrollo con Podman | Podman via `podman-compose` | SQLite3 por tenant (volumen) |
| **Staging** | Pruebas e integracion | gunicorn | SQLite3 por tenant |
| **Produccion** | Clientes reales | gunicorn + nginx | SQLite3 por tenant (archivo) |

## 2. Backend

### Estructura de Ejecucion

```
gunicorn app.main:app \
  --workers 4 \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000
```

### Variables de Entorno

| Variable | Descripcion | Default |
| -------- | ----------- | ------- |
| `DATABASE_DIR` | Directorio donde se almacenan los `.db` por tenant. | `./data/tenants` |
| `JWT_SECRET` | Secreto para firmar JWT. | Requerido |
| `JWT_ALGORITHM` | Algoritmo de firma. | `HS256` |
| `JWT_ACCESS_EXPIRE_MINUTES` | Duracion del access token. | `30` |
| `JWT_REFRESH_EXPIRE_DAYS` | Duracion del refresh token. | `7` |
| `CORS_ORIGINS` | Origenes permitidos (para debug). | `["http://localhost:3000"]` |
| `ENVIRONMENT` | Entorno activo. | `development` |

## 3. Contenedores (Podman)

Se usa **Podman** como runtime de contenedores (sin daemon, compatible con
Docker). Las imagenes base se obtienen de **AWS ECR Public** para evitar
dependencia de Docker Hub.

### Containerfile (Backend)

Ubicacion: `backend/Containerfile`

```dockerfile
# Build stage - AWS ECR Public image
FROM public.ecr.aws/docker/library/python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Runtime stage - AWS ECR Public image
FROM public.ecr.aws/docker/library/python:3.12-slim

WORKDIR /app

COPY --from=builder /install /usr/local
COPY app/ ./app/
COPY scripts/ ./scripts/

RUN mkdir -p /app/data/tenants /app/data/_global

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Orquestacion con podman-compose

Ubicacion: `podman-compose.yml` (raiz del proyecto)

```bash
# Construir y levantar
podman-compose up --build

# Levantar en background
podman-compose up -d

# Detener
podman-compose down

# Ver logs
podman-compose logs -f backend
```

### Build manual (sin compose)

Ubicacion: `backend/build.sh`

```bash
cd backend
./build.sh
```

Este script ejecuta `podman build` y `podman run` directamente.

### Imagenes AWS ECR Public

Todas las imagenes base usan el prefijo `public.ecr.aws/docker/library/`:

| Imagen | Uso |
| ------ | --- |
| `public.ecr.aws/docker/library/python:3.12-slim` | Backend FastAPI (build y runtime) |
| `public.ecr.aws/docker/library/ubuntu:24.04` | Flutter web dev container (SDK + hot reload) |

**Por que ECR Public y no Docker Hub:**
- Sin rate limits de descarga
- Sin autenticacion requerida para imagenes publicas
- CDN global de AWS con mejor latencia en America Latina
- Cumplimiento de politicas empresariales que restringen Docker Hub

## 3. Frontend (Flutter)

### Desarrollo Web (Hot Reload)

Flutter permite ejecutar la app en el navegador para desarrollo rapido,
sin necesidad de compilar para movil.

#### Containerfile (Flutter Web Dev)

Ubicacion: `mobile/Containerfile`

```dockerfile
# Base stage - AWS ECR Public image
FROM public.ecr.aws/docker/library/ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch stable \
    https://github.com/flutter/flutter.git "$FLUTTER_HOME"

RUN flutter precache --web \
    && yes | flutter doctor --android-licenses \
    && flutter doctor

# Development stage
FROM base AS dev
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get || true
EXPOSE 8080
CMD ["flutter", "run", "-d", "web-server", \
     "--web-port=8080", "--web-hostname=0.0.0.0"]
```

#### Orquestacion (podman-compose)

El servicio `flutter-web` esta incluido en `podman-compose.yml`:

```bash
# Levantar backend + Flutter web
podman-compose up --build

# Solo Flutter web (requiere backend corriendo)
podman-compose up flutter-web

# Primera vez: instalar dependencias
podman exec -it agua-flutter-web flutter pub get
```

Accede a `http://localhost:8080` en tu navegador. El Hot Reload funciona
via volume mount: editas el codigo en tu IDE y el navegador se actualiza
automaticamente.

#### Deteccion de Plataforma (baseUrl)

El `baseUrl` se detecta automaticamente segun la plataforma:

| Plataforma | URL | Motivo |
| ---------- | --- | ------ |
| **Web** | `http://localhost:8000` | El navegador corre en el host, localhost apunta al backend |
| **Android emulator** | `http://10.0.2.2:8000` | IP especial del emulador para acceder al host |

Configuracion en `lib/core/config/env_config.dart`:

```dart
import 'package:flutter/foundation.dart';

class EnvConfig {
  EnvConfig._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  static bool get isWeb => kIsWeb;
}
```

### Compilacion (Movil)

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Variables de Compilacion

| Variable | Descripcion |
| -------- | ----------- |
| `API_BASE_URL` | URL del backend API (ej: `https://api.agua.example.com/v1`). |

Se configuran en `lib/config/environment.dart` o via `--dart-define` al
compilar.

## 4. Nginx (Produccion)

```nginx
server {
    listen 443 ssl http2;
    server_name api.agua.example.com;

    ssl_certificate /etc/ssl/certs/agua.crt;
    ssl_certificate_key /etc/ssl/private/agua.key;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 5. Backup

### SQLite3

Cada `.db` de tenant se puede respaldar con:

```bash
sqlite3 data/tenants/empresa-abc/agua.db .dump > backup-empresa-abc.sql
```

Cron diario recomendado:

```bash
0 2 * * * for db in /app/data/tenants/*/agua.db; do
  name=$(basename $(dirname $db))
  sqlite3 $db .dump | gzip > /backups/agua-$name-$(date +\%Y\%m\%d).sql.gz
done
```

## 6. Monitoreo

| Metrica | Herramienta | Alerta si... |
| ------- | ----------- | ------------ |
| Tiempo de respuesta API | logs de nginx / gunicorn | > 2s promedio |
| Errores 5xx | logs de FastAPI | > 5 en 5 minutos |
| Disco (archivos .db) | script de monitoreo | > 80% uso |
| Disponibilidad | health check endpoint | No responde en 30s |
