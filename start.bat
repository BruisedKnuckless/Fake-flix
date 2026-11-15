@echo off
title FakeFlix
REM Go to the folder this file is in (so the server serves YOUR index.html)
cd /d "%~dp0"

echo == FakeFlix ==

REM ---- 1) Find Python (the only dependency) ----
set "PY="
py -3 --version >nul 2>&1
if not errorlevel 1 (set "PY=py -3" & goto :have_python)
python --version >nul 2>&1
if not errorlevel 1 (set "PY=python" & goto :have_python)

echo Python isn't installed. Installing it now with winget...
winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
  echo.
  echo Automatic install failed. Download Python from https://www.python.org/downloads/
  echo During setup, tick "Add python.exe to PATH".
  pause
  exit /b 1
)
echo.
echo Python installed! Close this window and double-click start.bat again.
pause
exit /b 0

:have_python
REM ---- 2) Find a free port, starting at 8000 ----
set PORT=8000
:find_port
netstat -an | findstr /c:":%PORT% " | findstr /c:"LISTENING" >nul
if not errorlevel 1 (set /a PORT+=1 & goto :find_port)

set "URL=http://localhost:%PORT%"
echo Starting server at %URL%

REM ---- 3) Work out this PC's address on the Wi-Fi, for phones and tablets ----
REM (This only asks the system which network address it would use. Nothing is sent.)
set "LAN_IP="
for /f "usebackq delims=" %%i in (`%PY% -c "import socket; s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(('10.255.255.255', 1)); print(s.getsockname()[0])" 2^>nul`) do set "LAN_IP=%%i"
if defined LAN_IP (
  echo.
  echo On a phone or tablet on the same Wi-Fi, open:  http://%LAN_IP%:%PORT%
  echo If Windows Firewall asks about Python, allow it on private networks.
  echo Anyone on this Wi-Fi can open that address while this window is running.
  echo.
)
echo Keep this window open. Press Ctrl+C or close the window to stop.

REM ---- 4) Open the browser after 2 seconds, in a separate minimized window ----
start "" /min cmd /c "timeout /t 2 /nobreak >nul & start %URL%"

REM ---- 5) Start the server (keeps running until you stop it) ----
REM 0.0.0.0 = reachable from other devices on your network, not just this PC.
REM Change it back to 127.0.0.1 to keep FakeFlix private to this computer.
%PY% -m http.server %PORT% --bind 0.0.0.0
pause
