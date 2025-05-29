import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';

/// Handles identification logic.
class Identify {
  static Future<void> identify(String projectId, String deviceToken) {
    return PntaFlutterPlatform.instance.identify(projectId, deviceToken);
  }
} 