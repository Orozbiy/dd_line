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

    // Badge тазалоо үчүн MethodChannel — optional cast (crash болбосун)
    if let controller = window?.rootViewController as? FlutterViewController {
      let badgeChannel = FlutterMethodChannel(
        name: "dd_online/badge",
        binaryMessenger: controller.binaryMessenger
      )
      badgeChannel.setMethodCallHandler { (call, result) in
        if call.method == "clearBadge" {
          DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
          }
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Колдонмо foreground'го келгенде badge автоматтык тазаланат
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    UIApplication.shared.applicationIconBadgeNumber = 0
  }
}
