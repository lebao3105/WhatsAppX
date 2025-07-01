@echo off
cd /d "%~dp0"
cmd /k "pkg server.js --targets node18-win-x64 --output app.exe"