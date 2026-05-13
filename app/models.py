from datetime import datetime
from pydantic import BaseModel, Field, field_validator


class AuthorIn(BaseModel):
    name: str = Field(min_length=1, max_length=200)

    @field_validator("name")
    @classmethod
    def strip_and_check_nonempty(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("name must not be blank")
        return v


class AuthorOut(BaseModel):
    id: int
    name: str
    created_at: datetime


class BookIn(BaseModel):
    title: str = Field(min_length=1, max_length=500)
    author_id: int = Field(ge=1)
    published: int | None = Field(default=None, ge=1, le=2999)

    @field_validator("title")
    @classmethod
    def strip_and_check_nonempty(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("title must not be blank")
        return v


class BookPatch(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=500)
    author_id: int | None = Field(default=None, ge=1)
    published: int | None = Field(default=None, ge=1, le=2999)


class BookOut(BaseModel):
    id: int
    title: str
    author_id: int
    published: int | None
    created_at: datetime


class AuthorWithBooks(AuthorOut):
    books: list[BookOut]
