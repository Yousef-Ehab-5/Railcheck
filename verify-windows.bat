@echo off
setlocal
cd /d "%~dp0"
call flutter analyze
if errorlevel 1 goto fail
call flutter test
if errorlevel 1 goto fail
call flutter build web --no-web-resources-cdn
if errorlevel 1 goto fail
echo All automated checks passed on this machine.
pause
exit /b 0
:fail
echo Verification stopped at the first failing command.
pause
exit /b 1
