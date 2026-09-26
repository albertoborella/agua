from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_DIR: str = "./data/tenants"
    JWT_SECRET: str = "dev-secret-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_EXPIRE_DAYS: int = 7
    # 8080 is the Flutter web dev server; 3000 is kept for the legacy web client.
    # Override with CORS_ORIGINS='["https://app.example.com"]' in production.
    CORS_ORIGINS: list[str] = [
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ]
    ENVIRONMENT: str = "development"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
