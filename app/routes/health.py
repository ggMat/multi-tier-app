from flask import Blueprint, jsonify

from app import db

bp = Blueprint("health", __name__)


@bp.get("/health")
def health():
    try:
        with db.get_conn() as conn:
            conn.execute("SELECT 1")
    except Exception:
        return jsonify({"status": "unhealthy"}), 503
    return jsonify({"status": "ok"}), 200
