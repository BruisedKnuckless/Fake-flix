@echo off
title Personal Netflix
REM Go to the folder this file is in (so the server serves YOUR index.html)
cd /d "%~dp0"

echo == Personal Netflix ==

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
echo Keep this window open. Press Ctrl+C or close the window to stop.

REM ---- 3) Open the browser after 2 seconds, in a separate minimized window ----
start "" /min cmd /c "timeout /t 2 /nobreak >nul & start %URL%"

REM ---- 4) Start the server (keeps running until you stop it) ----
%PY% -m http.server %PORT% --bind 127.0.0.1
pause
