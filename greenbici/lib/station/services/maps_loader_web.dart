import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('greenBiciMapsReady')
external set _mapsReady(JSFunction callback);

Future<void>? _loading;

/// Load only when Stations needs a map, keeping API keys out of index.html.
Future<void> prepareMaps(String apiKey) => _loading ??= _load(apiKey);

Future<void> _load(String apiKey) async {
  final ready = Completer<void>();
  final script = web.HTMLScriptElement()
    ..id = 'greenbici-google-maps'
    ..async = true
    ..src = Uri.https('maps.googleapis.com', '/maps/api/js', {
      'key': apiKey,
      'v': 'quarterly',
      'loading': 'async',
      'callback': 'greenBiciMapsReady',
    }).toString();

  _mapsReady = (() {
    if (!ready.isCompleted) ready.complete();
  }).toJS;
  script.onerror = ((web.Event event) {
    if (!ready.isCompleted) {
      ready.completeError(StateError('Could not load Google Maps.'));
    }
  }).toJS;

  web.document.head!.append(script);
  try {
    await ready.future.timeout(const Duration(seconds: 20));
  } catch (_) {
    // Allow the screen's Retry action to load a fresh script after a failure.
    script.remove();
    _loading = null;
    rethrow;
  } finally {
    script.onerror = null;
  }
}
