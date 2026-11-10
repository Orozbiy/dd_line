import Flutter
import UIKit
import YandexMapsMobile

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    YMKMapKit.setApiKey("619e1277-6ba0-426f-aa5b-9d3a900e0da2")
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let badgeChannel = FlutterMethodChannel(
        name: "dd_online/badge",
        binaryMessenger: controller.binaryMessenger
      )
      badgeChannel.setMethodCallHandler { (call, result) in
        DispatchQueue.main.async {
          if call.method == "clearBadge" {
            UIApplication.shared.applicationIconBadgeNumber = 0
            result(nil)
          } else if call.method == "setBadge",
                    let args = call.arguments as? [String: Any],
                    let count = args["count"] as? Int {
            UIApplication.shared.applicationIconBadgeNumber = count
            result(nil)
          } else {
            result(FlutterMethodNotImplemented)
          }
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    UIApplication.shared.applicationIconBadgeNumber = 0
  }
}
