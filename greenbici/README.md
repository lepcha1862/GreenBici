# GreenBici

A Flutter bicycle app with Home and nearby Stations screens. Home and Stations share the GreenBici header, search control, and bottom navigation. Rides, Notifications, and Profile are intentionally empty destinations for future integration.

## Run

Run commands from this `greenbici` directory. Use a Flutter SDK compatible with Dart `^3.13.4`; the current dependency lock requires Flutter 3.47 or newer.

```sh
flutter pub get
flutter run --dart-define-from-file=config/maps.local.json
```

The app runs without a Maps token: Stations keeps the always-visible CST fallback map and bundled demo markers in place of the live Mapbox map.

## Mapbox configuration

Create a public Mapbox access token and supply it through `MAPBOX_ACCESS_TOKEN`. See the [Mapbox Flutter installation guide](https://docs.mapbox.com/flutter/maps/guides/install/) and [access-token guide](https://docs.mapbox.com/help/dive-deeper/access-tokens/).

To keep the token out of shell history and tracked source files, copy `config/maps.example.json` to `config/maps.local.json`, enter the public token, then run:

```sh
flutter run --dart-define-from-file=config/maps.local.json
flutter run -d chrome --web-port=8080 --dart-define-from-file=config/maps.local.json
flutter build web --dart-define-from-file=config/maps.local.json
```

`config/*.local.json` is ignored by Git. Client map tokens are included in the built app, so apply URL restrictions to production web tokens in the Mapbox dashboard. A changed token requires a full rebuild/restart rather than hot reload.

The app initializes the Mapbox SDK from the Dart define before creating the first map. No Android manifest, iOS `AppDelegate`, or `web/index.html` token entry is required. This project targets Android API 24 or newer and iOS 15 or newer; Flutter web is supported by the selected Mapbox package. Desktop targets continue to use the CST fallback map.

## Location and station data

Stations requests location only when first opened. It obtains a foreground position and centers the map there. The center-location button requests a fresh position. Denied permission, permanently blocked permission, disabled location services, and timeouts have actionable states. Returning from device settings rechecks permission without automatically prompting again.

Android declares coarse and fine location permissions; approximate location is accepted. iOS declares a when-in-use purpose string. No background location tracking or background permission is requested. Web geolocation requires HTTPS or localhost; browser site settings control previously denied permissions. See the [geolocator platform setup](https://pub.dev/packages/geolocator).

The current `geolocator_apple` Swift package includes its optional Always-authorization code, although this app requests only when-in-use access. Before an App Store release, review the package's `BYPASS_PERMISSION_LOCATION_ALWAYS=1` guidance. The documented CocoaPods build hook does not apply to this SPM project; do not add an Always permission purpose string or background capability merely for this screen.

The Stations screen currently displays only the bundled CST demo stations and does not request station data from a network service. The demo markers are sorted by straight-line distance from the active map center and can be selected to open their preview details.

The shared top-navigation search is an explicit-submit location search. It uses Nominatim to resolve a city, landmark, or address, then recenters Mapbox without requesting GPS permission again. Queries are cached, requests are limited to one per second, autocomplete is intentionally disabled, and OpenStreetMap attribution remains visible. The public endpoint is suitable only for moderate development usage under the [Nominatim usage policy](https://operations.osmfoundation.org/policies/nominatim/). Production deployments should provide a policy-compliant proxy or hosted geocoder with `--dart-define=LOCATION_SEARCH_API_URL=https://your-service.example/search`.

`StaticStationRepository` supplies the preview markers. It can be replaced by an operator/GBFS-backed `StationRepository` when live station data becomes available. “Ride in Station” opens the Rides tab using the selected demo station; it does not launch external directions.

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
    services/               # GPS, station repository, and Mapbox configuration
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

The tests cover shared navigation, responsive layouts, GPS permission/error handling, station response parsing, sorting/searching, retry flows, and in-flight request disposal. Automated widget tests use the fallback map and do not contact Mapbox or request native permissions.

For this implementation, static analysis, all 200 automated tests, the release web build, and the Android ARM64 debug APK build pass. The supplied token also returns the Mapbox Streets style successfully. Android/iOS hardware behavior still requires the device checks below.

On a configured device/browser, also verify permission grant and denial, recovery through settings, initial centering and recentering, demo marker selection, search, zoom, the Ride in Station action, and tab switching. Test on an emulator with a supplied location or a device with location services enabled.

## Android build troubleshooting

On Windows, Kotlin's incremental compiler can fail with `this and base files have different roots` when plugin sources in the Pub cache are on `C:` and the project/build output is on `D:`. This project sets `kotlin.incremental=false` in `android/gradle.properties` to avoid that incremental-cache path conversion. Kotlin rebuilds can take longer because compilation is no longer incremental; Gradle's build cache remains available. See [Kotlin's incremental compilation documentation](https://kotlinlang.org/docs/gradle-compilation-and-caches.html#incremental-compilation).

If the build reports `CMake '3.22.1' was not found`, install that version through Android Studio's SDK Manager or run `android sdk install cmake/3.22.1` with the [Android CLI](https://developer.android.com/tools/agents/android-cli). It must be installed in the SDK referenced by `android/local.properties`.
