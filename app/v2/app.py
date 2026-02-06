from flask import Flask

app = Flask(__name__)

VERSION = "v2"

@app.route("/")
def home():
    return f"Hello from Virtual Server {VERSION}\n"

@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
