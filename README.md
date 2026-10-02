# RailCheck

An offline railway inspection **training simulator** with fictional trains and
three screens: Dashboard, Add report, and Details/Edit. It uses Flutter Material 3,
Floor/SQLite, geolocator, and shake. No account, API key, or backend is needed.

## 1. Finished behavior

- Dashboard: all-report counters, local search, status/priority filters, newest-updated
  ordering with descending ID as tie-breaker, loading/error/empty states.
- Add: six tappable carriages plus dropdown, train identifier, component, description,
  priority, optional explicitly requested foreground location.
- Details/Edit: full content and timestamps, field edits, status transitions,
  location removal/replacement, save, and confirmed deletion.
- Workflow: Open → In progress → Resolved. Save each transition before proceeding.
  Resolved → Open requires an explicit Reopen confirmation and clears the current
  resolution notes/time when saved. Resolution needs 10–1,000 trimmed characters.
- Train identifier: 1–30 trimmed characters, including letters. Description:
  10–1,000 trimmed characters. Invalid combinations are rejected in the repository,
  not just in the form. Unknown persisted values are shown and kept read-only.
- Shake twice on the foreground dashboard to request deletion of all reports.
  Repeated shakes cannot stack dialogs. A toolbar button provides the same flow
  on Web or when a device has no motion sensor. Deletion always needs confirmation.
- Saves are guarded against duplicate taps, failures retain form values, and Back
  warns about unsaved changes. Latitude/longitude/capture-time are all-null or
  all-present; finite coordinate ranges are validated. No fake fallback location.

## 2. Windows prerequisites

1. Install Flutter SDK and put its `bin` folder in your user PATH. Reopen the terminal.
2. Install Git and Android Studio. In SDK Manager install Android SDK Platform 36,
   Build Tools, Command-line Tools, and Android Emulator. Keep Android Studio's
   bundled JDK configured for Flutter; do not randomly switch Java versions.
3. Install VS Code's Flutter extension (it includes Dart), or Android Studio's
   Flutter and Dart plugins.
4. Install Chrome to run Web.
5. Run `flutter doctor -v` and `flutter doctor --android-licenses`.
   Missing Visual Studio is irrelevant when targeting Android/Web rather than
   Windows desktop. Windows desktop is outside this project's requested targets.

The reference toolchain for this deliverable is Flutter 3.35.7 / Dart 3.9.2.
Your installed SDK may be newer. See VERIFICATION.md for actual results and limits;
compatibility with an untested SDK version (including Flutter 3.44.6) is not claimed. A dependency lockfile is
included after successful resolution. Do not upgrade every package automatically:
Floor 1.5.0 uses an older generator toolchain.

## 3. Open and prepare the included project

Extract everything to a normal writable folder, such as `C:\Projects\railcheck`.
Open the directory containing `pubspec.yaml` in Android Studio or VS Code. Do not
open only `android`, do not run inside the ZIP, and do not use `C:\Windows\System32`.

Double-click **setup-windows.bat**, or run these commands in the project root:

```powershell
flutter --version
flutter pub get
dart run build_runner build --delete-conflicting-outputs
# Browser SQLite binaries are included; this regenerates them if ever needed:
dart run sqflite_common_ffi_web:setup
dart format lib test
flutter analyze
flutter test
```

The first setup needs internet for dependencies. Setup does not delete your database.
`app_database.g.dart` is machine-generated; never type or manually modify it.
After changing the entity/DAO, run build_runner again. Floor's analyzer 6.4.1 can
print an SDK-language-version warning; generation succeeded on the reference SDK.
Do not force analyzer 14 into Floor 1.5.0 to silence that warning.

For learning, the original platform-scaffold creation command was:

```powershell
flutter create --platforms=android,ios,web --org com.yousef --project-name railcheck railcheck
cd railcheck
```

You **do not** need to create a new project when using this ZIP. All handwritten
files are already included under their actual paths. Dependencies are declared in
pubspec.yaml; `flutter pub get` installs them. Equivalent version-selection commands:

```powershell
flutter pub add floor:1.5.0 sqflite:^2.4.2 sqflite_common_ffi_web:0.4.5+4 geolocator:14.0.2 geolocator_android:5.0.2 shake:3.0.0
flutter pub add dev:floor_generator:1.5.0 dev:build_runner:2.4.13
```

## 4. Run on Web, Pixel 8, or your phone

**Chrome:** double-click `run-web.bat`, or:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 7357
```

Always reuse the same browser, hostname and port so the origin's persistent
browser database remains the same. In VS Code select the supplied Chrome launch
configuration. Flutter Web's SQLite backend is experimental; it stores SQLite data
in browser-managed storage. Clearing site data, private browsing, eviction, or
switching origins can remove/hide those local records. Use one tab at a time.
No location, report, or account data is synced to a server.

**Pixel 8 emulator:** Android Studio → Device Manager → Create Device → Pixel 8 →
choose an installed Android system image → Finish → Start. Then:

```powershell
flutter devices
flutter run -d emulator-5554
```

Use the actual ID shown by `flutter devices`; it may not be `emulator-5554`.
In VS Code choose the running emulator from the bottom device selector and press F5.
In Android Studio choose it in the device dropdown and run `lib/main.dart`.
Set a simulated GPS position in emulator Extended Controls → Location.

**Android phone:** enable Developer options and USB debugging, connect a USB data
cable, accept the authorization prompt, run `flutter devices`, then
`flutter run -d YOUR_DEVICE_ID`. To build a locally installable test APK:

```powershell
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`. Copy it to your Android
phone to install, or use `flutter install --debug -d YOUR_DEVICE_ID`.
This ZIP contains source, not a prebuilt APK. Release-store signing is not configured.

**iOS:** requires macOS, Xcode, Apple signing for a real device, and any CocoaPods
setup requested by `flutter doctor`. On your Mac:

```bash
bash setup-macos.sh
flutter devices
flutter run -d YOUR_IOS_DEVICE_ID
```

Open `ios/Runner.xcworkspace` in Xcode when configuring the signing team. Windows
cannot build/run an iOS app. No background location entitlement is required.

## 5. Platform configuration (already applied)

`android/app/src/main/AndroidManifest.xml`: directly under `<manifest>` and above
`<application>`:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

There is no background-location request or foreground tracking service. The app
performs a single foreground position request only after the checkbox/replace action.
`android/app/build.gradle.kts` uses compile SDK 36 and the standard Flutter minimum
SDK configuration. `android/gradle.properties` enables AndroidX. The generated
Gradle wrapper (8.13), Kotlin (2.2.0), and Android Gradle Plugin (8.12.1) are included.
`geolocator_android` is explicitly pinned to 5.0.2 to retain AGP 8 compatibility.

Inside `ios/Runner/Info.plist`'s root `<dict>`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Attach your current position to an inspection report when you choose.</string>
<key>NSMotionUsageDescription</key>
<string>Detect a shake to offer deletion of training reports.</string>
```

The Podfile post-install hook preserves `flutter_additional_ios_build_settings`
and adds `BYPASS_PERMISSION_LOCATION_ALWAYS=1` for `geolocator_apple`.

For Web, `web/sqlite3.wasm` and `web/sqflite_sw.js` are produced by the package's
setup command. Serve them with the app. Localhost is suitable for development;
remote hosting needs HTTPS for browser location. Browser settings links cannot be
opened by geolocator; the UI explains how to use browser site settings instead.

## 6. Architecture and data flow

```text
lib/
  main.dart                         App entry and retryable database initialization
  theme/app_theme.dart              Material 3 engineering palette
  database/report.dart              Floor entity
  database/report_dao.dart          Annotated SQL/CRUD operations
  database/app_database.dart        Shared guarded initialization; schema version
  database/app_database.g.dart      Generated by Floor, not handwritten
  domain/values.dart                Stable stored strings, labels, local time
  domain/rules.dart                 Draft, validation, allowed transitions
  repositories/report_repository.dart  Validated serialized database writes
  controllers/write_controller.dart    ChangeNotifier submit guard and errors
  services/location_service.dart    Explicit one-shot foreground location
  screens/dashboard_screen.dart     Stable reactive subscription, filters, shakes
  screens/editor_screen.dart        Add and Details/Edit routes
  widgets/common.dart               Confirmation, badges, carriage selector
```

1. The form collects a `Draft`. Widget state holds temporary text and location.
2. Save enters `WriteController`, which immediately rejects simultaneous submits.
3. `ReportRepository` re-fetches the original, rejects stale or deleted records,
   and calls `Rules.prepare`. All entry points use these same validation rules.
4. The repository calls the Floor DAO. Generated Floor code converts the immutable
   `Report` into a SQLite insert/update and awaits its completion.
5. Floor's watched query emits the updated list. The dashboard's one stable
   subscription updates the list and counters.
6. UTC epoch milliseconds are stored; dates convert to local time only for display.
   Failed writes do not change the stored timestamps or dismiss the editor.

State management uses Flutter `setState` for screen-local fields plus a small
`ChangeNotifier` for writes. No provider framework is needed. Repositories contain
SQL-facing logic; widgets never create databases or query SQL directly. Streams,
text controllers, listeners, and shake detection are disposed with their screens.
Generation tokens ignore location completions after uncheck, replacement, or dispose.

In-memory filtering is appropriate for a classroom dataset. Thousands of large
records would warrant paginated DAO search, database indexes, and server-independent
storage performance tests. Local writes are serialized in this app instance;
multi-tab collaborative editing is not supported. A timestamp guard detects stale
edits but does not make cross-tab compare-and-swap atomic.

Schema version is 1. To change the schema, increment it and pass explicit Floor
`Migration` objects to the builder. Keep data and test migrations; never delete the
database as a repair strategy. There is intentionally no audit-history system.

## 7. Checks and troubleshooting

`verify-windows.bat` runs analyze, tests and a Web build. The included tests cover
validation boundaries, all status transition pairs, resolution/reopening, location
consistency, duplicate submission, failure retry, and Floor CRUD/stream behavior.
See VERIFICATION.md for what was actually run, and MANUAL-CHECKLIST.md for device tests.

- `Target of URI hasn't been generated` / missing `$FloorAppDatabase`:
  run `dart run build_runner build --delete-conflicting-outputs` in this folder.
- Browser database initialization fails: check the wasm/worker files, the stable
  localhost origin, storage permissions and browser console. Do not clear saved data
  as a first troubleshooting step.
- Dependency resolution fails on another SDK: keep the complete error and
  `flutter --version`. The supplied lockfile/reference toolchain is the baseline;
  do not add arbitrary dependency overrides.
- Windows error 4551 / App Control blocks `impellerc.exe`, `font-subset.exe` or a
  Flutter tool: this is a Windows security-policy block. Request an approved tool
  installation or administrator allowlisting; do not disable security protections.
- GPS timeout on emulator: provide a location in Extended Controls, then Retry.
- Permanent permission denial: use App settings. Approximate location is accepted
  and reported as such; coordinates are never fabricated.
- Data is local to each platform. Android reports will not appear in Chrome.
- Web CRUD works without backend connectivity after loading, but this is not a
  guaranteed offline-installable PWA. A server is required to initially serve the
  Web build. For a self-hosted engine bundle use:
  `flutter build web --no-web-resources-cdn`.
- Back interception protects in-app navigation. Closing the browser/tab or forcibly
  terminating the process can discard unsaved form input.

## 8. Package references

API documentation checked while preparing the project:

- https://pub.dev/packages/floor/versions/1.5.0
- https://pub.dev/packages/floor_generator/versions/1.5.0
- https://pub.dev/documentation/floor/latest/floor/sqfliteDatabaseFactory.html
- https://pub.dev/packages/build_runner/versions/2.4.13
- https://pub.dev/packages/sqflite_common_ffi_web/versions/0.4.5%2B4
- https://pub.dev/packages/geolocator/versions/14.0.2
- https://pub.dev/packages/shake/versions/3.0.0

Floor is kept as requested by the assignment. Its older generator constrains
build_runner/analyzer versions; selecting the newest version of every tool would
not be a sound compatibility strategy. The Web backend is documented as experimental.
