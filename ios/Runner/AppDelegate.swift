import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Fix: Remove "override" (this method does not exist in FlutterAppDelegate)
    @available(iOS 13.0, *)
    func application(
        _ application: UIApplication,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        for context in URLContexts {
            _ = handleIncomingFile(url: context.url)
        }
    }

    // Handles "Open In" for iOS 12 and older
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return handleIncomingFile(url: url)
    }

    // Function to process JSON files
    private func handleIncomingFile(url: URL) -> Bool {
        if url.pathExtension.lowercased() == "json" {
            let userDefaults = UserDefaults.standard
            userDefaults.set(url.absoluteString, forKey: "sharedJsonFile")
            userDefaults.synchronize()

            // Notify Flutter about the new file
            NotificationCenter.default.post(name: Notification.Name("importJson"), object: url.absoluteString)
            return true
        }
        return false
    }
}
