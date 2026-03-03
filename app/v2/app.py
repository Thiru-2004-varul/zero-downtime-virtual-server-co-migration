from flask import Flask, render_template_string, jsonify

app = Flask(__name__)
VERSION = "v2"

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
      background: #0d2b1d;
      color: white;
      padding: 20px;
    }
    h1 { color: #69f0ae; }
    .version-badge {
      background: #69f0ae;
      color: #0d2b1d;
      padding: 4px 12px;
      border-radius: 20px;
      font-weight: bold;
      margin-bottom: 20px;
    }
    .scoreboard {
      display: flex;
      gap: 30px;
      background: #1b4332;
      padding: 12px 30px;
      border-radius: 10px;
      margin-bottom: 15px;
      font-size: 1.1rem;
    }
    .scoreboard span { color: #69f0ae; font-weight: bold; }
    .board {
      display: grid;
      grid-template-columns: repeat(3, 100px);
      gap: 8px;
      margin: 20px 0;
    }
    .cell {
      width: 100px;
      height: 100px;
      background: #1b4332;
      border: 2px solid #69f0ae;
      border-radius: 8px;
      font-size: 2.5rem;
      font-weight: bold;
      cursor: pointer;
      color: white;
    }
    .cell:hover { background: #2d6a4f; }
    .status {
      font-size: 1.2rem;
      margin: 10px 0;
      color: #69f0ae;
    }
    .buttons { display: flex; gap: 10px; margin-top: 10px; }
    button {
      padding: 10px 30px;
      background: #69f0ae;
      color: #0d2b1d;
      border: none;
      border-radius: 6px;
      font-size: 1rem;
      font-weight: bold;
      cursor: pointer;
    }
    button:hover { background: #b7e4c7; }
    .upgrade-note {
      margin-top: 20px;
      font-size: 0.85rem;
      color: #95d5b2;
      background: #1b4332;
      padding: 8px 16px;
      border-radius: 6px;
    }
  </style>
</head>
<body>
  <h1>Tic Tac Toe</h1>
  <div class="version-badge">{{ version }} - Pro Edition</div>

  <div class="scoreboard">
    X Wins: <span id="scoreX">0</span>
    &nbsp;|&nbsp;
    Draws: <span id="scoreDraw">0</span>
    &nbsp;|&nbsp;
    O Wins: <span id="scoreO">0</span>
  </div>

  <div class="status" id="status">Player X's turn</div>
  <div class="board" id="board">
    {% for i in range(9) %}
    <button class="cell" onclick="play({{ i }})" id="cell-{{ i }}"></button>
    {% endfor %}
  </div>
  <div class="buttons">
    <button onclick="resetGame()">Next Round</button>
    <button onclick="resetScore()">Reset Score</button>
  </div>
  <div class="upgrade-note">
    ✅ Migrated from v1 → v2 with zero downtime using Rolling Update strategy
  </div>

  <script>
    let board = Array(9).fill('');
    let currentPlayer = 'X';
    let gameOver = false;
    let scores = { X: 0, O: 0, Draw: 0 };

    const wins = [
      [0,1,2],[3,4,5],[6,7,8],
      [0,3,6],[1,4,7],[2,5,8],
      [0,4,8],[2,4,6]
    ];

    function play(i) {
      if (board[i] || gameOver) return;
      board[i] = currentPlayer;
      document.getElementById('cell-' + i).textContent = currentPlayer;

      if (checkWin()) {
        document.getElementById('status').textContent = 'Player ' + currentPlayer + ' Wins! 🎉';
        scores[currentPlayer]++;
        updateScore();
        gameOver = true;
        return;
      }
      if (board.every(c => c)) {
        document.getElementById('status').textContent = "It's a Draw!";
        scores.Draw++;
        updateScore();
        gameOver = true;
        return;
      }
      currentPlayer = currentPlayer === 'X' ? 'O' : 'X';
      document.getElementById('status').textContent = "Player " + currentPlayer + "'s turn";
    }

    function checkWin() {
      return wins.some(([a,b,c]) =>
        board[a] && board[a] === board[b] && board[b] === board[c]
      );
    }

    function updateScore() {
      document.getElementById('scoreX').textContent = scores.X;
      document.getElementById('scoreO').textContent = scores.O;
      document.getElementById('scoreDraw').textContent = scores.Draw;
    }

    function resetGame() {
      board = Array(9).fill('');
      currentPlayer = 'X';
      gameOver = false;
      document.getElementById('status').textContent = "Player X's turn";
      for (let i = 0; i < 9; i++) {
        document.getElementById('cell-' + i).textContent = '';
      }
    }

    function resetScore() {
      scores = { X: 0, O: 0, Draw: 0 };
      updateScore();
      resetGame();
    }
  </script>
</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(HTML, version=VERSION)

@app.route("/health")
def health():
    return jsonify({"status": "ok", "version": VERSION}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
# updated
