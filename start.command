#!/bin/bash
# Personal Netflix: double-click to start (macOS)

# Go to the folder this file is in (so the server serves YOUR index.html)
cd "$(dirname "$0")" || exit 1

echo "== Personal Netflix =="

# ---- 1) Make sure Python 3 works (it's the only dependency) ----
if ! python3 --version >/dev/null 2>&1; then
  echo "Python 3 isn't installed."
  echo "A window should pop up asking to install Command Line Tools. Click Install."
  xcode-select --install 2>/dev/null
  echo "When it finishes, double-click start.command again."
  read -r -p "Press Enter to close..."
  exit 1
fi

# ---- 2) Find a free port, starting at 8000 ----
PORT=8000
while lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; do
  PORT=$((PORT + 1))
done

URL="http://localhost:$PORT"
echo "Starting server at $URL"
echo "Keep this window open. Press Ctrl+C (or close the window) to stop."

# ---- 3) Open the browser after 1 second, in the background (&) ----
(sleep 1 && open "$URL") &

# ---- 4) Start the server (keeps running until you stop it) ----
python3 -m http.server "$PORT" --bind 127.0.0.1
