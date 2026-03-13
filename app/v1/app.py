from flask import Flask, render_template_string, jsonify, Response
import time

app = Flask(__name__)
VERSION = "v1"

request_count = 0
start_time = time.time()

HTML = """
<!DOCTYPE html>
<html>
<head>
  <title>Tic Tac Toe - {{ version }}</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      background: #1a1a2e;
      color: white;
      padding: 20px;
    }
    h1 { color: #4fc3f7; }
    .version-badge {
      background: #4fc3f7;
      color: #1a1a2e;
      padding: 4px 12px;
      border-radius: 20px;
      font-weight: bold;
      margin-bottom: 20px;
    }
    .board {
      display: grid;
      grid-template-columns: repeat(3, 100px);
      gap: 8px;
      margin: 20px 0;
    }
    .cell {
      width: 100px;
      height: 100px;
      background: #16213e;
      border: 2px solid #4fc3f7;
      border-radius: 8px;
      font-size: 2.5rem;
      font-weight: bold;
      cursor: pointer;
      color: white;
    }
    .cell:hover { background: #0f3460; }
    .status { font-size: 1.2rem; margin: 10px 0; color: #4fc3f7; }
    button {
      margin-top: 10px;
      padding: 10px 30px;
      background: #4fc3f7;
      color: #1a1a2e;
      border: none;
      border-radius: 6px;
      font-size: 1rem;
      font-weight: bold;
      cursor: pointer;
    }
    button:hover { background: #81d4fa; }
  </style>
</head>
<body>
  <h1>Tic Tac Toe</h1>
  <div class="version-badge">{{ version }} - Basic Edition</div>
  <div class="status" id="status">Player X's turn</div>
  <div class="board">
    {% for i in range(9) %}
    <button class="cell" onclick="play({{ i }})" id="cell-{{ i }}"></button>
    {% endfor %}
  </div>
  <button onclick="resetGame()">Restart</button>
  <script>
    let board = Array(9).fill('');
    let currentPlayer = 'X';
    let gameOver = false;
    const wins = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
    function play(i) {
      if (board[i] || gameOver) return;
      board[i] = currentPlayer;
      document.getElementById('cell-' + i).textContent = currentPlayer;
      if (checkWin()) {
        document.getElementById('status').textContent = 'Player ' + currentPlayer + ' Wins!';
        gameOver = true; return;
      }
      if (board.every(c => c)) {
        document.getElementById('status').textContent = "It's a Draw!";
        gameOver = true; return;
      }
      currentPlayer = currentPlayer === 'X' ? 'O' : 'X';
      document.getElementById('status').textContent = "Player " + currentPlayer + "'s turn";
    }
    function checkWin() {
      return wins.some(([a,b,c]) => board[a] && board[a] === board[b] && board[b] === board[c]);
    }
    function resetGame() {
      board = Array(9).fill('');
      currentPlayer = 'X';
      gameOver = false;
      document.getElementById('status').textContent = "Player X's turn";
      for (let i = 0; i < 9; i++) document.getElementById('cell-' + i).textContent = '';
    }
  </script>
</body>
</html>
"""

@app.route("/")
def home():
    global request_count
    request_count += 1
    return render_template_string(HTML, version=VERSION)

@app.route("/health")
def health():
    return jsonify({"status": "ok", "version": VERSION}), 200

@app.route("/metrics")
def metrics():
    uptime = time.time() - start_time
    output = f"""# HELP app_requests_total Total requests
# TYPE app_requests_total counter
app_requests_total{{version="{VERSION}"}} {request_count}
# HELP app_uptime_seconds App uptime in seconds
# TYPE app_uptime_seconds gauge
app_uptime_seconds{{version="{VERSION}"}} {uptime:.2f}
# HELP app_up App is running
# TYPE app_up gauge
app_up{{version="{VERSION}"}} 1
"""
    return Response(output, mimetype="text/plain")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
