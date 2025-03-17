import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ Add this function to handle "Open In" file URLs
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.pathExtension == "json" {
      let userDefaults = UserDefaults.standard
      userDefaults.set(url.absoluteString, forKey: "sharedJsonFile")
      userDefaults.synchronize()
      
      NotificationCenter.default.post(name: Notification.Name("importJson"), object: url.absoluteString)
      return true
    }
    return false
  }
}
