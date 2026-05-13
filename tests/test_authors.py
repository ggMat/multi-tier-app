import pytest


@pytest.fixture
def client(clean_db):
    from app import create_app
    return create_app().test_client()


def test_list_authors_empty(client):
    r = client.get("/authors")
    assert r.status_code == 200
    assert r.get_json() == []


def test_create_author(client):
    r = client.post("/authors", json={"name": "Hemingway"})
    assert r.status_code == 201
    body = r.get_json()
    assert body["name"] == "Hemingway"
    assert isinstance(body["id"], int)
    assert "created_at" in body


def test_create_author_validation_error(client):
    r = client.post("/authors", json={"name": "   "})
    assert r.status_code == 422


def test_create_author_missing_body(client):
    r = client.post("/authors", json={})
    assert r.status_code == 422


def test_get_author_with_embedded_books(client):
    a = client.post("/authors", json={"name": "Hemingway"}).get_json()
    r = client.get(f"/authors/{a['id']}")
    assert r.status_code == 200
    body = r.get_json()
    assert body["name"] == "Hemingway"
    assert body["books"] == []


def test_get_author_404(client):
    r = client.get("/authors/9999")
    assert r.status_code == 404


def test_update_author(client):
    a = client.post("/authors", json={"name": "X"}).get_json()
    r = client.put(f"/authors/{a['id']}", json={"name": "Y"})
    assert r.status_code == 200
    assert r.get_json()["name"] == "Y"


def test_update_author_404(client):
    r = client.put("/authors/9999", json={"name": "Z"})
    assert r.status_code == 404


def test_delete_author(client):
    a = client.post("/authors", json={"name": "X"}).get_json()
    r = client.delete(f"/authors/{a['id']}")
    assert r.status_code == 204
    r2 = client.get(f"/authors/{a['id']}")
    assert r2.status_code == 404


def test_delete_author_404(client):
    r = client.delete("/authors/9999")
    assert r.status_code == 404
