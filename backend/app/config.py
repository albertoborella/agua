from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_DIR: str = "./data/tenants"
    JWT_SECRET: str = "dev-secret-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_EXPIRE_DAYS: int = 7
    # Explicit allowlist, used as-is in production. 8080 is the Flutter web dev
    # server; 3000 is kept for the legacy web client.
    # Override with CORS_ORIGINS='["https://app.example.com"]' in production.
    CORS_ORIGINS: list[str] = [
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ]
    ENVIRONMENT: str = "development"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    @property
    def is_development(self) -> bool:
        return self.ENVIRONMENT.lower() in {"development", "dev", "local"}

    @property
    def cors_allow_origin_regex(self) -> str | None:
        """Extra origins allowed only while developing.

        A hardcoded allowlist breaks the moment the app is opened somewhere
        else: `0.0.0.0` because the Flutter dev server advertises that address,
        or a LAN IP when testing on a phone or tablet. Those are all local
        addresses, so in development we accept loopback and private ranges and
        keep the strict list for production.

        Covers localhost, 127.0.0.1, 0.0.0.0, [::1], 10/8, 172.16/12 and
        192.168/16, with an optional port.
        """
        if not self.is_development:
            return None
        return (
            r"^https?://("
            r"localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\]"
            r"|10\.\d{1,3}\.\d{1,3}\.\d{1,3}"
            r"|192\.168\.\d{1,3}\.\d{1,3}"
            r"|172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3}"
            r")(:\d{1,5})?$"
        )


settings = Settings()
