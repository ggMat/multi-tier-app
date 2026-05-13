import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Config:
    db_host: str
    db_port: int
    db_name: str
    db_user: str
    db_password: str
    app_port: int
    log_level: str

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            db_host=os.environ["DB_HOST"],
            db_port=int(os.environ["DB_PORT"]),
            db_name=os.environ["DB_NAME"],
            db_user=os.environ["DB_USER"],
            db_password=os.environ["DB_PASSWORD"],
            app_port=int(os.environ.get("APP_PORT", "8000")),
            log_level=os.environ.get("LOG_LEVEL", "INFO"),
        )

    @property
    def database_url(self) -> str:
        return (
            f"postgresql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )
