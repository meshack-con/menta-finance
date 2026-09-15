from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str
    jwt_secret_key: str
    jwt_access_token_expire_minutes: int = 480
    cors_origins: str = "http://localhost:3000"
    seed_admin_username: str = "admin"
    seed_admin_password: str
    seed_manager_username: str = "manager"
    seed_manager_password: str

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
