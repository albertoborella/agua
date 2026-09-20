# Despliegue

## 1. Entornos

| Entorno | Proposito | Backend | DB |
| ------- | --------- | ------- | -- |
| **Local** | Desarrollo individual | `uvicorn` en localhost:8000 | SQLite3 archivo local |
| **Staging** | Pruebas e integracion | `uvicorn` o gunicorn | SQLite3 por tenant |
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

### Dockerfile (Backend)

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["gunicorn", "app.main:app", \
     "--workers", "4", \
     "--worker-class", "uvicorn.workers.UvicornWorker", \
     "--bind", "0.0.0.0:8000"]
```

## 3. Frontend (Flutter)

### Compilacion

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
