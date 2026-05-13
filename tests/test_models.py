import pytest
from pydantic import ValidationError
from app.models import AuthorIn, AuthorOut, BookIn, BookOut


def test_author_in_requires_name():
    with pytest.raises(ValidationError):
        AuthorIn()


def test_author_in_strips_whitespace():
    a = AuthorIn(name="  Hemingway  ")
    assert a.name == "Hemingway"


def test_author_in_rejects_empty_name():
    with pytest.raises(ValidationError):
        AuthorIn(name="   ")


def test_author_out_serializes():
    from datetime import datetime, timezone
    a = AuthorOut(id=1, name="X", created_at=datetime(2026, 1, 1, tzinfo=timezone.utc))
    assert a.model_dump()["name"] == "X"


def test_book_in_requires_title_and_author_id():
    with pytest.raises(ValidationError):
        BookIn(title="x")
    with pytest.raises(ValidationError):
        BookIn(author_id=1)


def test_book_in_published_optional():
    b = BookIn(title="t", author_id=1)
    assert b.published is None


def test_book_in_published_range():
    with pytest.raises(ValidationError):
        BookIn(title="t", author_id=1, published=0)
    with pytest.raises(ValidationError):
        BookIn(title="t", author_id=1, published=3000)
