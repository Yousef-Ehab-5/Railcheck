@echo off
setlocal
cd /d "%~dp0"
call flutter run -d chrome --web-hostname localhost --web-port 7357
if errorlevel 1 pause
