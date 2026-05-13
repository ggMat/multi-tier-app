from contextlib import contextmanager
from typing import Iterator

import psycopg
from psycopg_pool import ConnectionPool

from app.config import Config

_pool: ConnectionPool | None = None


def init_pool(cfg: Config | None = None) -> None:
    global _pool
    if _pool is not None:
        return
    cfg = cfg or Config.from_env()
    _pool = ConnectionPool(cfg.database_url, min_size=1, max_size=4, open=True)


@contextmanager
def get_conn() -> Iterator[psycopg.Connection]:
    if _pool is None:
        init_pool()
    assert _pool is not None
    with _pool.connection() as conn:
        yield conn
