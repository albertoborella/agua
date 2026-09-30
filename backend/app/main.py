from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import init_global_db
from app.routers import admin, alerts, auth, catalog, lab, samples


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_global_db()
    yield


app = FastAPI(
    title="Agua - Control de Calidad de Agua",
    description="Sistema multi-tenant de control de calidad de agua potable",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    # Local network origins (0.0.0.0, LAN IPs for phone/tablet testing) in
    # development only. Starlette echoes the matched origin back, so this stays
    # compatible with allow_credentials.
    allow_origin_regex=settings.cors_allow_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(catalog.router)
app.include_router(samples.router)
app.include_router(lab.router)
app.include_router(alerts.router)


@app.get("/health")
def health_check():
    return {"status": "ok"}
