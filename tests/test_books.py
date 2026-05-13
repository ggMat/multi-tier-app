import pytest


@pytest.fixture
def client(clean_db):
    from app import create_app
    return create_app().test_client()


@pytest.fixture
def author_id(client):
    return client.post("/authors", json={"name": "Hemingway"}).get_json()["id"]


def test_list_books_empty(client):
    r = client.get("/books")
    assert r.status_code == 200
    assert r.get_json() == []


def test_create_book(client, author_id):
    r = client.post("/books", json={
        "title": "The Old Man and the Sea", "author_id": author_id, "published": 1952,
    })
    assert r.status_code == 201
    body = r.get_json()
    assert body["title"] == "The Old Man and the Sea"
    assert body["author_id"] == author_id
    assert body["published"] == 1952


def test_create_book_without_published(client, author_id):
    r = client.post("/books", json={"title": "X", "author_id": author_id})
    assert r.status_code == 201
    assert r.get_json()["published"] is None


def test_create_book_unknown_author_returns_400(client):
    r = client.post("/books", json={"title": "X", "author_id": 9999})
    assert r.status_code == 400


def test_list_books_filter_by_author(client, author_id):
    other = client.post("/authors", json={"name": "Y"}).get_json()["id"]
    client.post("/books", json={"title": "A", "author_id": author_id})
    client.post("/books", json={"title": "B", "author_id": other})
    r = client.get(f"/books?author_id={author_id}")
    assert r.status_code == 200
    titles = [b["title"] for b in r.get_json()]
    assert titles == ["A"]


def test_get_book(client, author_id):
    b = client.post("/books", json={"title": "T", "author_id": author_id}).get_json()
    r = client.get(f"/books/{b['id']}")
    assert r.status_code == 200
    assert r.get_json()["title"] == "T"


def test_get_book_404(client):
    r = client.get("/books/9999")
    assert r.status_code == 404


def test_update_book_partial(client, author_id):
    b = client.post("/books", json={"title": "T", "author_id": author_id}).get_json()
    r = client.put(f"/books/{b['id']}", json={"title": "U"})
    assert r.status_code == 200
    body = r.get_json()
    assert body["title"] == "U"
    assert body["author_id"] == author_id


def test_update_book_404(client):
    r = client.put("/books/9999", json={"title": "X"})
    assert r.status_code == 404


def test_delete_book(client, author_id):
    b = client.post("/books", json={"title": "T", "author_id": author_id}).get_json()
    r = client.delete(f"/books/{b['id']}")
    assert r.status_code == 204
    assert client.get(f"/books/{b['id']}").status_code == 404


def test_delete_book_404(client):
    r = client.delete("/books/9999")
    assert r.status_code == 404


def test_deleting_author_cascades_to_books(client, author_id):
    b = client.post("/books", json={"title": "T", "author_id": author_id}).get_json()
    assert client.delete(f"/authors/{author_id}").status_code == 204
    assert client.get(f"/books/{b['id']}").status_code == 404
