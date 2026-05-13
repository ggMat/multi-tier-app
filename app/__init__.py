import logging
import os

from flask import Flask, jsonify
from pydantic import ValidationError

from app.config import Config
from app.db import init_pool


def create_app(config: Config | None = None) -> Flask:
    app = Flask(__name__)
    cfg = config or Config.from_env()

    logging.basicConfig(level=cfg.log_level)
    init_pool(cfg)

    from app.routes.health import bp as health_bp
    app.register_blueprint(health_bp)

    @app.errorhandler(ValidationError)
    def _ve(err: ValidationError):
        return jsonify({"error": "validation", "details": err.errors()}), 422

    @app.errorhandler(404)
    def _nf(_):
        return jsonify({"error": "not found"}), 404

    @app.errorhandler(Exception)
    def _ise(err: Exception):
        app.logger.exception("unhandled")
        return jsonify({"error": "internal server error"}), 500

    return app
