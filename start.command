#!/bin/bash
# FakeFlix: double-click to start (macOS)

# Go to the folder this file is in (so the server serves YOUR index.html)
cd "$(dirname "$0")" || exit 1

echo "== FakeFlix =="

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

# ---- 3) Work out this Mac's address on the Wi-Fi, for phones and tablets ----
# (This only asks the system which network address it would use. Nothing is sent.)
LAN_IP=$(python3 -c 'import socket; s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(("10.255.255.255", 1)); print(s.getsockname()[0])' 2>/dev/null)
if [ -n "$LAN_IP" ]; then
  echo
  echo "On a phone or tablet on the same Wi-Fi, open:  http://$LAN_IP:$PORT"
  echo "(If macOS asks whether Python may accept incoming connections, click Allow.)"
  echo "Anyone on this Wi-Fi can open that address while this window is running."
  echo
fi
echo "Keep this window open. Press Ctrl+C (or close the window) to stop."

# ---- 4) Open the browser after 1 second, in the background (&) ----
(sleep 1 && open "$URL") &

# ---- 5) Start the server (keeps running until you stop it) ----
# 0.0.0.0 = reachable from other devices on your network, not just this Mac.
# Change it back to 127.0.0.1 to keep FakeFlix private to this computer.
python3 -m http.server "$PORT" --bind 0.0.0.0
