@echo off
setlocal
cd /d "%~dp0"
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter was not found. Add your Flutter bin folder to PATH and reopen the terminal.
  pause
  exit /b 1
)
call flutter --version
if errorlevel 1 goto fail
call flutter pub get
if errorlevel 1 goto fail
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 goto fail
if not exist web\sqlite3.wasm goto websetup
if not exist web\sqflite_sw.js goto websetup
goto checks
:websetup
call dart run sqflite_common_ffi_web:setup
if errorlevel 1 goto fail
:checks
call dart format lib test
if errorlevel 1 goto fail
call flutter analyze
if errorlevel 1 goto fail
echo.
echo Setup complete. Run run-web.bat, or start your emulator and use flutter run.
echo Run flutter test separately to verify business rules on your machine.
pause
exit /b 0
:fail
echo.
echo Setup stopped because the command above failed. Your source and saved reports were not deleted.
echo Copy the FIRST error and the output of flutter --version if you need help.
pause
exit /b 1
