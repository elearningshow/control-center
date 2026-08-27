@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Control Center
cd /d "%~dp0"

if not defined CC_KEEPOPEN (
    set "CC_KEEPOPEN=1"
    cmd /k "%~f0" %*
    exit /b
)

set "PULL_MODEL="
for %%A in (%*) do (
    set "ARG=%%~A"
    if /i "!ARG:~0,7!"=="/model=" set "PULL_MODEL=!ARG:~7!"
)

set "REPO_URL=https://github.com/mreflow/control-center.git"
set "REPO_ZIP=https://github.com/mreflow/control-center/archive/refs/heads/main.zip"
set "NODE_VER=24.20.0"
set "NODE_HOME=%LOCALAPPDATA%\ControlCenter-Runtime\node"
set "DATA_DIR=%LOCALAPPDATA%\Control Center"
set "OLLAMA_URL=http://127.0.0.1:11434"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

rem In-repo: setup.bat sits next to package.json.
rem Outside-repo: setup.bat sits beside a control-center folder.
if exist "%SCRIPT_DIR%\package.json" (
    findstr /C:"self-hosted-control-center" "%SCRIPT_DIR%\package.json" >nul 2>&1
    if not errorlevel 1 (
        set "INSTALL_DIR=%SCRIPT_DIR%"
        goto HAVE_DIR
    )
)
if exist "%SCRIPT_DIR%\control-center\package.json" (
    set "INSTALL_DIR=%SCRIPT_DIR%\control-center"
    goto HAVE_DIR
)
set "INSTALL_DIR=%SCRIPT_DIR%\control-center"

:HAVE_DIR
echo.
echo  Control Center setup
echo  Project: %INSTALL_DIR%
echo.

if exist "%NODE_HOME%\node.exe" goto NODE_OK
if exist "%ProgramFiles%\nodejs\node.exe" set "NODE_HOME=%ProgramFiles%\nodejs" & goto NODE_OK

echo Downloading portable Node.js %NODE_VER%...
set "ARCH=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"
set "ZIP=%TEMP%\node-v%NODE_VER%-win-%ARCH%.zip"
if not exist "%ZIP%" curl.exe -L --fail -o "%ZIP%" "https://nodejs.org/dist/v%NODE_VER%/node-v%NODE_VER%-win-%ARCH%.zip"
if not exist "%ZIP%" goto FAIL
set "EXTRACT=%TEMP%\cc-node-unpack"
if exist "%EXTRACT%" rmdir /s /q "%EXTRACT%"
mkdir "%EXTRACT%"
tar.exe --force-local -xf "%ZIP%" -C "%EXTRACT%" 2>nul
if not exist "%EXTRACT%\node-v%NODE_VER%-win-%ARCH%\node.exe" (
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%EXTRACT%' -Force"
)
if not exist "%NODE_HOME%" mkdir "%NODE_HOME%"
robocopy "%EXTRACT%\node-v%NODE_VER%-win-%ARCH%" "%NODE_HOME%" /E /NFL /NDL /NJH /NJS /NP >nul
if not exist "%NODE_HOME%\node.exe" goto FAIL

:NODE_OK
set "PATH=%NODE_HOME%;%LOCALAPPDATA%\Programs\Ollama;%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\WindowsPowerShell\v1.0"
echo Node:
"%NODE_HOME%\node.exe" -v

if exist "%INSTALL_DIR%\package.json" goto SOURCE_OK
echo Downloading Control Center...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
where git >nul 2>&1
if not errorlevel 1 (
    git clone --depth 1 "%REPO_URL%" "%INSTALL_DIR%"
    if not errorlevel 1 goto SOURCE_OK
)
set "APPZIP=%TEMP%\control-center-main.zip"
curl.exe -L --fail -o "%APPZIP%" "%REPO_ZIP%"
tar.exe --force-local -xf "%APPZIP%" -C "%TEMP%" 2>nul
if exist "%TEMP%\control-center-main\package.json" xcopy /e /i /y /q "%TEMP%\control-center-main\*" "%INSTALL_DIR%\" >nul
if not exist "%INSTALL_DIR%\package.json" goto FAIL

:SOURCE_OK
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if exist "%INSTALL_DIR%\.env.example" if not exist "%INSTALL_DIR%\.env.local" copy /y "%INSTALL_DIR%\.env.example" "%INSTALL_DIR%\.env.local" >nul
if exist "%SCRIPT_DIR%\start.bat" if /i not "%SCRIPT_DIR%"=="%INSTALL_DIR%" copy /y "%SCRIPT_DIR%\start.bat" "%INSTALL_DIR%\start.bat" >nul
if exist "%SCRIPT_DIR%\REQUIREMENTS.md" if /i not "%SCRIPT_DIR%"=="%INSTALL_DIR%" copy /y "%SCRIPT_DIR%\REQUIREMENTS.md" "%INSTALL_DIR%\REQUIREMENTS.md" >nul
echo Source ready.

if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" set "PATH=%LOCALAPPDATA%\Programs\Ollama;%PATH%"
where ollama >nul 2>&1
if errorlevel 1 (
    echo Ollama not found. Dashboard will still run.
    goto APP
)
curl.exe -s -m 2 "%OLLAMA_URL%/api/tags" >nul 2>&1
if errorlevel 1 start "Ollama" /MIN cmd /c "ollama serve"

set "MODEL="
if not "%PULL_MODEL%"=="" (
    echo Downloading requested model %PULL_MODEL%...
    ollama pull %PULL_MODEL%
    set "MODEL=%PULL_MODEL%"
) else (
    echo Local Ollama models:
    ollama list
    for /f "skip=1 tokens=1" %%M in ('ollama ps 2^>nul') do if not defined MODEL set "MODEL=%%M"
    if not defined MODEL for /f "skip=1 tokens=1" %%M in ('ollama list 2^>nul') do if not defined MODEL set "MODEL=%%M"
)

if "%MODEL%"=="" (
    echo No local model selected. Nothing will be downloaded.
    echo Optional later:  ollama pull qwen2.5:7b
    echo Or:              setup.bat /model=qwen2.5:7b
    goto APP
)

echo Using existing model %MODEL%
curl.exe -s -m 60 "%OLLAMA_URL%/api/generate" -H "Content-Type: application/json" -d "{\"model\":\"%MODEL%\",\"prompt\":\"ok\",\"stream\":false,\"keep_alive\":-1}" >nul 2>&1
"%NODE_HOME%\node.exe" -e "const fs=require('fs'),path=require('path');const p=path.join(process.env.LOCALAPPDATA,'Control Center','settings.json');let s={};try{s=JSON.parse(fs.readFileSync(p,'utf8').replace(/^\uFEFF/,''))}catch(e){} s.ai=s.ai||{};s.ai.provider='ollama';s.ai.model=process.env.MODEL;s.ai.localBaseUrls=Object.assign({lmstudio:'http://127.0.0.1:1234',ollama:'http://127.0.0.1:11434'},s.ai.localBaseUrls||{});fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n');"

:APP
cd /d "%INSTALL_DIR%"
if exist "%DATA_DIR%\launcher.lock" del /f /q "%DATA_DIR%\launcher.lock" >nul 2>&1
"%NODE_HOME%\node.exe" -e "const fs=require('fs'),p=require('path').join(process.env.LOCALAPPDATA,'Control Center','settings.json');if(!fs.existsSync(p))process.exit(0);const b=fs.readFileSync(p);if(b[0]===0xEF&&b[1]===0xBB&&b[2]===0xBF)fs.writeFileSync(p,b.subarray(3));"

echo Installing app packages...
call "%NODE_HOME%\npm.cmd" run setup
if errorlevel 1 call "%NODE_HOME%\npm.cmd" ci
if not exist "node_modules\next\dist\bin\next" goto FAIL
if not exist ".next\BUILD_ID" (
    echo Building dashboard...
    call "%NODE_HOME%\npm.cmd" run build
    if errorlevel 1 goto FAIL
)

echo.
echo Starting server. Leave this window open.
echo Dashboard: http://127.0.0.1:3000
echo.
start "" "http://127.0.0.1:3000"
"%NODE_HOME%\node.exe" "node_modules\next\dist\bin\next" start --hostname 127.0.0.1 --port 3000
echo.
echo Server stopped.
pause
exit /b 0

:FAIL
echo.
echo Setup could not finish. Check the message above.
pause
exit /b 1
