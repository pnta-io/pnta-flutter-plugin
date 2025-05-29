import 'src/permission.dart';

class PntaFlutter {
  static Future<bool> requestNotificationPermission() {
    return Permission.requestNotificationPermission();
  }
}
