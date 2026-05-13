def test_health_returns_ok(clean_db):
    from app import create_app
    app = create_app()
    client = app.test_client()
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_health_returns_503_when_db_down(monkeypatch, clean_db):
    from app import create_app
    from app import db as db_module
    monkeypatch.setattr(
        db_module, "get_conn",
        lambda: (_ for _ in ()).throw(RuntimeError("db down")),
    )
    app = create_app()
    client = app.test_client()
    resp = client.get("/health")
    assert resp.status_code == 503
