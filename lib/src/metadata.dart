import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';

/// Handles metadata update logic.
class Metadata {
  static Future<void> updateMetadata(String projectId,
      {Map<String, dynamic>? metadata}) {
    return PntaFlutterPlatform.instance.updateMetadata(projectId, metadata: metadata);
  }
}
