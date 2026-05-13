import os
from pathlib import Path
import pytest
from testcontainers.postgres import PostgresContainer


@pytest.fixture(scope="session")
def postgres_container():
    with PostgresContainer("postgres:16-alpine") as pg:
        yield pg


@pytest.fixture(scope="session")
def db_env(postgres_container):
    """Set DB_* env vars to point at the testcontainer."""
    url = postgres_container.get_connection_url()
    # url format: postgresql+psycopg2://user:pass@host:port/db
    # strip the driver suffix for our psycopg3 use
    from urllib.parse import urlparse
    parsed = urlparse(url.replace("postgresql+psycopg2", "postgresql"))
    os.environ["DB_HOST"] = parsed.hostname
    os.environ["DB_PORT"] = str(parsed.port)
    os.environ["DB_NAME"] = parsed.path.lstrip("/")
    os.environ["DB_USER"] = parsed.username
    os.environ["DB_PASSWORD"] = parsed.password
    os.environ["APP_PORT"] = "8000"
    yield


@pytest.fixture(scope="session")
def initialized_db(db_env):
    """Apply the migration once per session."""
    import psycopg
    from app.config import Config
    cfg = Config.from_env()
    sql = (Path(__file__).parent.parent / "app" / "migrations" / "001_init.sql").read_text()
    with psycopg.connect(cfg.database_url, autocommit=True) as conn:
        conn.execute(sql)
    yield


@pytest.fixture
def clean_db(initialized_db):
    """Truncate tables between tests."""
    import psycopg
    from app.config import Config
    cfg = Config.from_env()
    with psycopg.connect(cfg.database_url, autocommit=True) as conn:
        conn.execute("TRUNCATE authors RESTART IDENTITY CASCADE")
    yield
