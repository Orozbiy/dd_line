import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  // Тиркеме ачылган/активдешкен сайын иконкадагы кызыл сан өчүрүлөт.
  // (SceneDelegate болгондо AppDelegate'тин applicationDidBecomeActive
  // методу чакырылбайт — badge ошон үчүн өчпөй жүргөн.)
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    if #available(iOS 16.0, *) {
      UNUserNotificationCenter.current().setBadgeCount(0)
    } else {
      UIApplication.shared.applicationIconBadgeNumber = 0
    }
  }
}
