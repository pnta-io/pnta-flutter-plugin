import 'src/permission.dart';
import 'src/token.dart';
import 'src/identify.dart';
import 'src/foreground.dart';

class PntaFlutter {
  static Future<bool> requestNotificationPermission() {
    return Permission.requestNotificationPermission();
  }

  static Future<String?> getDeviceToken() {
    return Token.getDeviceToken();
  }

  static Future<void> identify(String projectId, String deviceToken) {
    return Identify.identify(projectId, deviceToken);
  }

  /// Emits notification payloads when received while the app is in the foreground.
  static Stream<Map<String, dynamic>> get foregroundNotifications =>
      foregroundNotificationsStream;

  /// Configures whether the native system UI should be shown for foreground notifications.
  static Future<void> setForegroundPresentationOptions({required bool showSystemUI}) {
    return setForegroundPresentationOptionsInternal(showSystemUI: showSystemUI);
  }
}
