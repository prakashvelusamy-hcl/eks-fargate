from flask import Flask
from models import db
from config import SQLALCHEMY_DATABASE_URI
from routes import bp
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

app.config["SQLALCHEMY_DATABASE_URI"] = SQLALCHEMY_DATABASE_URI
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)
app.register_blueprint(bp, url_prefix="/api")

@app.route("/")
def index():
    return "Employee Directory API is running"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)


