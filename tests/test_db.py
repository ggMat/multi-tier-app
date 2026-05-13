def test_get_conn_yields_working_connection(clean_db):
    from app.db import get_conn
    with get_conn() as conn:
        cur = conn.execute("SELECT 1")
        assert cur.fetchone()[0] == 1


def test_get_conn_uses_pool(clean_db):
    from app.db import get_conn, _pool
    assert _pool is not None
    with get_conn() as conn:
        conn.execute("SELECT 1")
