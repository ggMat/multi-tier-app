CREATE TABLE IF NOT EXISTS authors (
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS books (
    id          SERIAL PRIMARY KEY,
    title       TEXT NOT NULL,
    author_id   INTEGER NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
    published   INTEGER,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_books_author_id ON books(author_id);
