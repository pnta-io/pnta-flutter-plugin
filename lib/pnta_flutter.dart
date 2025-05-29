import 'src/permission.dart';
import 'src/token.dart';
import 'src/identify.dart';

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
}
