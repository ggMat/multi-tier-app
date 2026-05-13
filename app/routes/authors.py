from flask import Blueprint, jsonify, request

from app.db import get_conn
from app.models import AuthorIn, AuthorOut, AuthorWithBooks, BookOut

bp = Blueprint("authors", __name__)


@bp.get("/authors")
def list_authors():
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT id, name, created_at FROM authors ORDER BY id"
        ).fetchall()
    return jsonify([
        AuthorOut(id=r[0], name=r[1], created_at=r[2]).model_dump(mode="json")
        for r in rows
    ])


@bp.post("/authors")
def create_author():
    payload = AuthorIn.model_validate(request.get_json(silent=True) or {})
    with get_conn() as conn:
        row = conn.execute(
            "INSERT INTO authors (name) VALUES (%s) RETURNING id, name, created_at",
            (payload.name,),
        ).fetchone()
        conn.commit()
    return jsonify(
        AuthorOut(id=row[0], name=row[1], created_at=row[2]).model_dump(mode="json")
    ), 201


@bp.get("/authors/<int:author_id>")
def get_author(author_id: int):
    with get_conn() as conn:
        row = conn.execute(
            "SELECT id, name, created_at FROM authors WHERE id = %s",
            (author_id,),
        ).fetchone()
        if row is None:
            return jsonify({"error": "not found"}), 404
        books = conn.execute(
            "SELECT id, title, author_id, published, created_at "
            "FROM books WHERE author_id = %s ORDER BY id",
            (author_id,),
        ).fetchall()
    body = AuthorWithBooks(
        id=row[0],
        name=row[1],
        created_at=row[2],
        books=[
            BookOut(id=b[0], title=b[1], author_id=b[2], published=b[3], created_at=b[4])
            for b in books
        ],
    )
    return jsonify(body.model_dump(mode="json"))


@bp.put("/authors/<int:author_id>")
def update_author(author_id: int):
    payload = AuthorIn.model_validate(request.get_json(silent=True) or {})
    with get_conn() as conn:
        row = conn.execute(
            "UPDATE authors SET name = %s WHERE id = %s "
            "RETURNING id, name, created_at",
            (payload.name, author_id),
        ).fetchone()
        conn.commit()
        if row is None:
            return jsonify({"error": "not found"}), 404
    return jsonify(
        AuthorOut(id=row[0], name=row[1], created_at=row[2]).model_dump(mode="json")
    )


@bp.delete("/authors/<int:author_id>")
def delete_author(author_id: int):
    with get_conn() as conn:
        deleted = conn.execute(
            "DELETE FROM authors WHERE id = %s RETURNING id", (author_id,)
        ).fetchone()
        conn.commit()
    if deleted is None:
        return jsonify({"error": "not found"}), 404
    return "", 204
