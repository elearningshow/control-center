@echo off
if not defined CC_KEEPOPEN (
  set "CC_KEEPOPEN=1"
  title Control Center
  cmd /k "%~f0" %*
  exit /b
)
title Control Center
cd /d "F:\AI\apps\mattwolfe\control-center"
set "NODE_HOME=C:\Users\SODKGB\AppData\Local\ControlCenter-Runtime\node"
if not exist "%NODE_HOME%\node.exe" set "NODE_HOME=%ProgramFiles%\nodejs"
set "PATH=%NODE_HOME%;%LOCALAPPDATA%\Programs\Ollama;%SystemRoot%\System32;%SystemRoot%"
echo Starting Control Center...
echo This window IS the server. Do not close it.
echo Dashboard: http://127.0.0.1:3000
echo Leave the Ollama app running for local AI.
echo.
if exist "%LOCALAPPDATA%\Control Center\launcher.lock" del /f /q "%LOCALAPPDATA%\Control Center\launcher.lock" >nul 2>&1
where ollama >nul 2>&1
if not errorlevel 1 (
  curl.exe -s -m 2 http://127.0.0.1:11434/api/tags >nul 2>&1
  if errorlevel 1 start "Ollama Serve" /MIN cmd /c "ollama serve"
)
"%NODE_HOME%\node.exe" -v
"%NODE_HOME%\node.exe" "scripts\launch.mjs"
if errorlevel 1 "%NODE_HOME%\node.exe" "node_modules\next\dist\bin\next" start --hostname 127.0.0.1 --port 3000
echo.
echo Control Center stopped. This window will stay open.
pause
