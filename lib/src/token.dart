import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';

/// Handles device token retrieval (APNs on iOS, FCM on Android).
class Token {
  /// Gets the device push notification token (APNs on iOS, FCM on Android).
  static Future<String?> getDeviceToken() {
    return PntaFlutterPlatform.instance.getDeviceToken();
  }
}
