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

  // ✅ Handle "Open In" and "Share" files (iOS 14+)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return handleIncomingFile(url: url)
  }

  // ✅ Handle new-style URL opening (iOS 14+)
  override func application(
    _ application: UIApplication,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts {
      handleIncomingFile(url: context.url)
    }
  }

  // ✅ Function to process JSON files
  private func handleIncomingFile(url: URL) -> Bool {
    if url.pathExtension.lowercased() == "json" {
      let userDefaults = UserDefaults.standard
      userDefaults.set(url.absoluteString, forKey: "sharedJsonFile")
      userDefaults.synchronize()

      // 🔥 Notify Flutter about the new file
      NotificationCenter.default.post(name: Notification.Name("importJson"), object: url.absoluteString)
      return true
    }
    return false
  }
}
