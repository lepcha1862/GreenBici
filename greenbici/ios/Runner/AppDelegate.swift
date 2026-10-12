import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Match the Dart configuration without checking a Maps key into source.
    if let encodedDefines = Bundle.main.object(forInfoDictionaryKey: "GreenBiciDartDefines") as? String {
      for entry in encodedDefines.split(separator: ",") {
        guard let data = Data(base64Encoded: String(entry)),
              let define = String(data: data, encoding: .utf8),
              define.hasPrefix("GOOGLE_MAPS_API_KEY=") else { continue }
        let key = String(define.dropFirst("GOOGLE_MAPS_API_KEY=".count))
          .trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty { GMSServices.provideAPIKey(key) }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
