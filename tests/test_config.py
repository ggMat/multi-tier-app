import os
import pytest
from app.config import Config


def test_config_loads_from_env(monkeypatch):
    monkeypatch.setenv("DB_HOST", "db.example.com")
    monkeypatch.setenv("DB_PORT", "5432")
    monkeypatch.setenv("DB_NAME", "mydb")
    monkeypatch.setenv("DB_USER", "user")
    monkeypatch.setenv("DB_PASSWORD", "secret")
    monkeypatch.setenv("APP_PORT", "8000")
    cfg = Config.from_env()
    assert cfg.db_host == "db.example.com"
    assert cfg.db_port == 5432
    assert cfg.db_name == "mydb"
    assert cfg.db_user == "user"
    assert cfg.db_password == "secret"
    assert cfg.app_port == 8000
    assert cfg.log_level == "INFO"  # default


def test_config_log_level_override(monkeypatch):
    monkeypatch.setenv("DB_HOST", "h")
    monkeypatch.setenv("DB_PORT", "5432")
    monkeypatch.setenv("DB_NAME", "n")
    monkeypatch.setenv("DB_USER", "u")
    monkeypatch.setenv("DB_PASSWORD", "p")
    monkeypatch.setenv("LOG_LEVEL", "DEBUG")
    cfg = Config.from_env()
    assert cfg.log_level == "DEBUG"


def test_config_missing_required_raises(monkeypatch):
    for k in ("DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"):
        monkeypatch.delenv(k, raising=False)
    with pytest.raises(KeyError):
        Config.from_env()


def test_config_database_url(monkeypatch):
    monkeypatch.setenv("DB_HOST", "h")
    monkeypatch.setenv("DB_PORT", "5432")
    monkeypatch.setenv("DB_NAME", "n")
    monkeypatch.setenv("DB_USER", "u")
    monkeypatch.setenv("DB_PASSWORD", "p")
    cfg = Config.from_env()
    assert cfg.database_url == "postgresql://u:p@h:5432/n"
