// Smart bike lock domain models.
//
// Part of the MQTT smart lock feature mounted in the Unlock section of the
// Rides screen. Self contained: nothing outside `lib/ride/mqtt/` uses these.

/// Where the physical lock currently is, as reported on the status topic.
enum BikeLockStatus { locked, unlocked, unknown }

/// Lifecycle of the MQTT connection to the broker.
enum BikeConnectionStatus {
  /// Never connected and not attempting to connect.
  idle,

  /// First connection attempt in flight.
  connecting,

  /// Connected, subscribed and able to publish.
  connected,

  /// Lost the connection, the client is automatically reconnecting.
  reconnecting,

  /// Explicitly disconnected by the user.
  disconnected,
}

/// A status update received from the bike on the status topic.
class BikeLockUpdate {
  const BikeLockUpdate({required this.status, required this.raw, this.at});

  final BikeLockStatus status;

  /// The original payload string, useful for debugging in the UI.
  final String raw;
  final DateTime? at;
}

/// Normalises whatever the ESP32 sends on the status topic into a
/// [BikeLockStatus]. Understands plain words (`LOCK`, `UNLOCK`, `LOCKED`,
/// `unlocked`, `1`, `0`) as well as JSON payloads such as
/// `{"lock":"UNLOCKED"}` or `{"status": 0}`.
BikeLockStatus parseBikeLockPayload(String payload) {
  final text = payload.trim().toLowerCase();
  if (text.isEmpty) return BikeLockStatus.unknown;

  // JSON object: look for the usual lock/state/status keys.
  if (text.startsWith('{')) {
    final match = RegExp(
      '"(?:lock|lockstate|lock_state|state|status)"\\s*:\\s*"?([a-z0-9_]+)"?',
    ).firstMatch(text);
    return _statusFromToken(match?.group(1) ?? text);
  }
  return _statusFromToken(text);
}

BikeLockStatus _statusFromToken(String token) {
  final value = token.trim();
  // Match unlock before lock: "unlock" contains the letters "lock".
  if (value.contains('unlock') || value == 'open' || value == '0') {
    return BikeLockStatus.unlocked;
  }
  if (value.contains('lock') ||
      value == 'close' ||
      value == 'closed' ||
      value == '1') {
    return BikeLockStatus.locked;
  }
  return BikeLockStatus.unknown;
}
