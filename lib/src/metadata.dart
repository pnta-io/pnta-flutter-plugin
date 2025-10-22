import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';

/// Handles metadata update logic.
class Metadata {
  static Future<void> updateMetadata(
    String projectId, {
    Map<String, dynamic>? metadata,
  }) {
    if (projectId.trim().isEmpty) {
      throw ArgumentError('Project ID cannot be empty');
    }

    return PntaFlutterPlatform.instance.updateMetadata(
      projectId.trim(),
      metadata,
    );
  }
}
