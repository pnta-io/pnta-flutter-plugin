import 'src/permission.dart';
import 'src/token.dart';

class PntaFlutter {
  static Future<bool> requestNotificationPermission() {
    return Permission.requestNotificationPermission();
  }

  static Future<String?> getDeviceToken() {
    return Token.getDeviceToken();
  }
}
