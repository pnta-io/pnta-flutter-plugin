import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';

/// Handles notification permission requests.
class Permission {
  /// Requests notification permission from the user.
  static Future<bool> requestNotificationPermission() {
    return PntaFlutterPlatform.instance.requestNotificationPermission();
  }
} 