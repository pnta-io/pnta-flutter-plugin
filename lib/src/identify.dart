import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';

/// Handles identification logic.
class Identify {
  static Future<void> identify(String projectId, String deviceToken, {Map<String, dynamic>? metadata}) {
    return PntaFlutterPlatform.instance.identify(projectId, deviceToken, metadata);
  }
}
