# GreenBici

A Flutter bicycle app with Home and nearby Stations screens. Home and Stations share the GreenBici header, search control, and bottom navigation. Rides, Notifications, and Profile are intentionally empty destinations for future integration.

## Run

Run commands from this `greenbici` directory. Use a Flutter SDK compatible with Dart `^3.13.4`; the current dependency lock requires Flutter 3.47 or newer.

```sh
flutter pub get
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_PLATFORM_KEY
```

The app runs without a Maps key: after location permission is granted, Stations still searches for nearby stations and displays its results, with a map-unavailable message in place of the map.

## Google Maps configuration

Create a Google Cloud project with billing enabled and enable the API for the target platform. Use a separate restricted key per platform, supplied through the same `GOOGLE_MAPS_API_KEY` setting. See the [Google Maps Flutter setup](https://developers.google.com/maps/flutter-package/config) and [API key restrictions](https://developers.google.com/maps/api-security-best-practices).

| Target | Minimum | Enable | Restrict the key to |
| --- | --- | --- | --- |
| Android | API 24 | Maps SDK for Android | Application ID and signing certificate SHA-1 |
| iOS | iOS 15 | Maps SDK for iOS | Bundle identifier |
| Web | Supported Flutter browser | Maps JavaScript API | Authorized HTTP referrers, including your development origin |

The current Android application ID and iOS bundle identifier are both `com.example.greenbici`. Update their key restrictions when changing those identifiers. Desktop native Google Maps views are not supported; use an Android/iOS device or the web target.

To keep the key out of shell history and source files, copy `config/maps.example.json` to `config/maps.local.json`, enter the platform key, then run:

```sh
flutter run --dart-define-from-file=config/maps.local.json
flutter run -d chrome --web-port=8080 --dart-define-from-file=config/maps.local.json
flutter build web --dart-define-from-file=config/maps.local.json
```

`config/*.local.json` is ignored by Git. Client Maps keys are included in the built app, so configure the platform and API restrictions above. A changed key requires a full rebuild/restart, rather than hot reload.

The Android Gradle configuration decodes Flutter's `dart-defines` into the Maps manifest entry. iOS reads Flutter's `DART_DEFINES` build setting through `Info.plist` and initializes `GMSServices` in `AppDelegate`. Web loads the Maps JavaScript API on demand before creating the map; no manual key insertion into `web/index.html` is needed.

For iOS, build on macOS with Xcode. The project already uses Swift Package Manager and selects `google_maps_flutter_ios_sdk9` to retain iOS 15 support. Run Flutter with the key before launching directly from Xcode so `ios/Flutter/Generated.xcconfig` contains the current build settings. See the [iOS Maps implementation](https://pub.dev/packages/google_maps_flutter_ios_sdk9).

## Location and station data

Stations requests location only when first opened. It obtains a foreground position, centers the map there, and searches within 5 km. The center-location button requests a fresh position. Denied permission, permanently blocked permission, disabled location services, timeouts, and network failures have actionable states. Returning from device settings rechecks permission without automatically prompting again.

Android declares coarse and fine location permissions; approximate location is accepted. iOS declares a when-in-use purpose string. No background location tracking or background permission is requested. Web geolocation requires HTTPS or localhost; browser site settings control previously denied permissions. See the [geolocator platform setup](https://pub.dev/packages/geolocator).

The current `geolocator_apple` Swift package includes its optional Always-authorization code, although this app requests only when-in-use access. Before an App Store release, review the package's `BYPASS_PERMISSION_LOCATION_ALWAYS=1` guidance. The documented CocoaPods build hook does not apply to this SPM project; do not add an Always permission purpose string or background capability merely for this screen.

Nearby station locations come from OpenStreetMap `amenity=bicycle_rental` records through the public Overpass API (`https://overpass.private.coffee/api/interpreter`). Results are sorted by straight-line distance and can be filtered by station or operator name. Coverage depends on OpenStreetMap contributors and public API availability. The location coordinates are sent to Overpass for the nearby search and to Google when displaying the map or opening directions.

For a production deployment, select an Overpass service appropriate to your traffic and pass `--dart-define=OVERPASS_API_URL=https://your-service.example/api/interpreter` when running or building. The repository also accepts an injected HTTPS `endpoint` for integration. A web deployment's endpoint must allow cross-origin requests. The current public default is listed in the [official OSM instance directory](https://wiki.openstreetmap.org/wiki/Overpass_API#Public_Overpass_API_instances). Native requests identify the application as GreenBici; browsers provide their own request identity. Requests time out after 20 seconds and the screen offers retry. Live verification in the development environment encountered public-server timeouts, so successful live station retrieval and browser CORS behavior remain to be checked on the target device or deployment.

OpenStreetMap does not provide live bike/dock availability. The screen reports that availability is unavailable instead of inventing counts from the reference design. `StationRepository` can be replaced by an operator/GBFS-backed implementation when live data becomes available. `Get Directions` opens Google Maps walking directions to the selected station. Station data attribution links to [OpenStreetMap contributors](https://www.openstreetmap.org/copyright).

## Structure

```text
lib/
  navbar/
    app_shell.dart           # Tab state, lazy Station creation, shared scaffold
    top_nav.dart             # Wordmark, title/greeting, reusable search control
    bottom_nav.dart          # Shared five-destination navigation
  home/                     # Existing Home content
  station/
    station_page.dart       # Responsive layout and user actions
    station_controller.dart # Location, search, selection, and loading state
    models/                 # Coordinates and bicycle station model
    services/               # GPS, station repository, Maps configuration/loading
    widgets/                # Map, markers, details, and status messages
  theme/app_style.dart      # Shared colors and theme
```

The shell preserves Home scroll state and Station selection/search while switching tabs. Location and repository interfaces, plus an injectable map builder, keep widget tests independent of native Maps views and real GPS/network access.

## Verify

```sh
flutter analyze
flutter test
flutter build web
```

The tests cover shared navigation, responsive layouts, GPS permission/error handling, station response parsing, sorting/searching, retry flows, and in-flight request disposal. Web builds were checked both without a key and with a dummy build-only key to compile the enabled Maps path. These checks do not verify Google credentials or native permissions.

For this implementation, static analysis, the automated tests, the release web build (including Flutter's Wasm compatibility check), and the Android ARM64 debug APK build pass. The Android APK was also assembled offline after installing CMake 3.22.1. Android/iOS hardware behavior and a map using a real Google API key still require the device checks below.

On a configured device/browser, also verify permission grant and denial, recovery through settings, initial centering and recentering, marker selection, search, zoom, directions, and tab switching. Test on an emulator with a supplied location or a device with location services enabled.

## Android build troubleshooting

On Windows, Kotlin's incremental compiler can fail with `this and base files have different roots` when plugin sources in the Pub cache are on `C:` and the project/build output is on `D:`. This project sets `kotlin.incremental=false` in `android/gradle.properties` to avoid that incremental-cache path conversion. Kotlin rebuilds can take longer because compilation is no longer incremental; Gradle's build cache remains available. See [Kotlin's incremental compilation documentation](https://kotlinlang.org/docs/gradle-compilation-and-caches.html#incremental-compilation).

If the build reports `CMake '3.22.1' was not found`, install that version through Android Studio's SDK Manager or run `android sdk install cmake/3.22.1` with the [Android CLI](https://developer.android.com/tools/agents/android-cli). It must be installed in the SDK referenced by `android/local.properties`.
