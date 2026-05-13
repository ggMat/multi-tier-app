from flask import Blueprint, jsonify, request
from psycopg.errors import ForeignKeyViolation

from app.db import get_conn
from app.models import BookIn, BookOut, BookPatch

bp = Blueprint("books", __name__)


def _row_to_book(row) -> BookOut:
    return BookOut(
        id=row[0], title=row[1], author_id=row[2],
        published=row[3], created_at=row[4],
    )


@bp.get("/books")
def list_books():
    author_id = request.args.get("author_id", type=int)
    with get_conn() as conn:
        if author_id is not None:
            rows = conn.execute(
                "SELECT id, title, author_id, published, created_at "
                "FROM books WHERE author_id = %s ORDER BY id",
                (author_id,),
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT id, title, author_id, published, created_at "
                "FROM books ORDER BY id"
            ).fetchall()
    return jsonify([_row_to_book(r).model_dump(mode="json") for r in rows])


@bp.post("/books")
def create_book():
    payload = BookIn.model_validate(request.get_json(silent=True) or {})
    try:
        with get_conn() as conn:
            row = conn.execute(
                "INSERT INTO books (title, author_id, published) "
                "VALUES (%s, %s, %s) "
                "RETURNING id, title, author_id, published, created_at",
                (payload.title, payload.author_id, payload.published),
            ).fetchone()
            conn.commit()
    except ForeignKeyViolation:
        return jsonify({"error": f"author_id {payload.author_id} does not exist"}), 400
    return jsonify(_row_to_book(row).model_dump(mode="json")), 201


@bp.get("/books/<int:book_id>")
def get_book(book_id: int):
    with get_conn() as conn:
        row = conn.execute(
            "SELECT id, title, author_id, published, created_at "
            "FROM books WHERE id = %s",
            (book_id,),
        ).fetchone()
    if row is None:
        return jsonify({"error": "not found"}), 404
    return jsonify(_row_to_book(row).model_dump(mode="json"))


@bp.put("/books/<int:book_id>")
def update_book(book_id: int):
    payload = BookPatch.model_validate(request.get_json(silent=True) or {})
    fields = payload.model_dump(exclude_unset=True)
    if not fields:
        with get_conn() as conn:
            row = conn.execute(
                "SELECT id, title, author_id, published, created_at "
                "FROM books WHERE id = %s", (book_id,),
            ).fetchone()
        if row is None:
            return jsonify({"error": "not found"}), 404
        return jsonify(_row_to_book(row).model_dump(mode="json"))

    set_clause = ", ".join(f"{k} = %s" for k in fields)
    values = list(fields.values()) + [book_id]
    try:
        with get_conn() as conn:
            row = conn.execute(
                f"UPDATE books SET {set_clause} WHERE id = %s "
                "RETURNING id, title, author_id, published, created_at",
                values,
            ).fetchone()
            conn.commit()
    except ForeignKeyViolation:
        return jsonify({"error": "author_id does not exist"}), 400
    if row is None:
        return jsonify({"error": "not found"}), 404
    return jsonify(_row_to_book(row).model_dump(mode="json"))


@bp.delete("/books/<int:book_id>")
def delete_book(book_id: int):
    with get_conn() as conn:
        deleted = conn.execute(
            "DELETE FROM books WHERE id = %s RETURNING id", (book_id,)
        ).fetchone()
        conn.commit()
    if deleted is None:
        return jsonify({"error": "not found"}), 404
    return "", 204
