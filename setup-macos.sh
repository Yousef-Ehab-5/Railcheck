#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
flutter pub get
dart run build_runner build --delete-conflicting-outputs
if [[ ! -f web/sqlite3.wasm || ! -f web/sqflite_sw.js ]]; then
  dart run sqflite_common_ffi_web:setup
fi
dart format lib test
flutter analyze
printf '%s\n' 'Setup complete. Use flutter devices, then flutter run -d DEVICE_ID.'
