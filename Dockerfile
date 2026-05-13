# syntax=docker/dockerfile:1.7

FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.12-slim
RUN useradd -r -u 1000 app \
 && apt-get update \
 && apt-get install -y --no-install-recommends libpq5 postgresql-client \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /root/.local /home/app/.local
COPY --chown=app:app app/ ./app/
USER app
ENV PATH=/home/app/.local/bin:$PATH PYTHONUNBUFFERED=1
EXPOSE 8000
CMD ["sh", "-c", "psql \"$DATABASE_URL\" -f app/migrations/001_init.sql && gunicorn --bind 0.0.0.0:${APP_PORT:-8000} --workers 2 --access-logfile - 'app:create_app()'"]
