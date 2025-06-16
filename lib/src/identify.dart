import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';

/// Handles identification logic.
class Identify {
  static Future<String?> identify(String projectId) {
    if (projectId.trim().isEmpty) {
      throw ArgumentError('Project ID cannot be empty');
    }

    return PntaFlutterPlatform.instance.identify(projectId.trim());
  }
}
