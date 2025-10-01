from flask import Flask
import socket, os

app = Flask(__name__)

@app.route("/")
def index():
    return {
        "message": "Hello from Multi-Tier App",
        "host": socket.gethostname(),
        "env": dict(os.environ)
    }

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
