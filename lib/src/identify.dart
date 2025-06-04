import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';

/// Handles identification logic.
class Identify {
  static Future<String?> identify(String projectId, {Map<String, dynamic>? metadata}) {
    return PntaFlutterPlatform.instance.identify(projectId, metadata: metadata);
  }
}
