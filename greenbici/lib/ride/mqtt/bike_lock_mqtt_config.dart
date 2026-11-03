/// Connection settings for the smart bike lock (Rides screen Unlock section).
///
/// EMQX Cloud TLS endpoint used by the ESP32 bike lock demo.
abstract final class BikeLockMqttConfig {
  /// EMQX Cloud broker host, TLS listener. Replace with the endpoint shown in
  /// your EMQX Cloud deployment (e.g. `xxx.s1.eu.emqxcloud.cn`).
  static const String brokerHost = String.fromEnvironment(
    'MQTT_BROKER_HOST',
    defaultValue: 'c116d364.ala.asia-southeast1.emqxsl.com',
  );

  /// Secure MQTT port.
  static const int brokerPort = 8883;

  static const String username = 'GreenBici';
  static const String password = 'Solar@123!';

  /// Topic the ESP32 publishes its lock status on.
  static const String statusTopic = 'ebike/lock01/status';

  /// Identifier the ESP32 itself connects with. The app must never reuse it:
  /// EMQX closes the existing session when a second client arrives with the
  /// same identifier, so the phone and the bike would keep kicking each other
  /// off the broker.
  static const String deviceClientId = 'ebike-lock-01';

  /// Prefix of the app session identifier. A unique suffix is appended per
  /// connection, so several phones can control the same bike at once.
  static const String clientIdPrefix = 'greenbici-app-lock01';

  /// Topic the app publishes `LOCK` / `UNLOCK` commands on.
  static const String commandTopic = 'ebike/lock01/cmd';

  /// Command payloads expected by the ESP32 firmware.
  static const String unlockCommand = 'UNLOCK';
  static const String lockCommand = 'LOCK';

  /// The ESP32 relocks the bike automatically this long after an UNLOCK.
  static const int autoRelockSeconds = 15;

  /// MQTT keep alive in seconds.
  static const int keepAliveSeconds = 20;

  /// True once a broker host has been provided (const or --dart-define).
  static bool get isConfigured => brokerHost.trim().isNotEmpty;
}
