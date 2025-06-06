import 'package:flutter/foundation.dart';
import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';

/// Handles metadata update logic.
class Metadata {
  static Future<void> updateMetadata(String projectId,
      {Map<String, dynamic>? metadata}) {
    // Validate projectId
    if (projectId.trim().isEmpty) {
      debugPrint('PNTA: Invalid projectId - cannot be empty');
      throw ArgumentError('Project ID cannot be empty');
    }
    
    if (projectId.length > 100) {
      debugPrint('PNTA: Invalid projectId - too long (${projectId.length} chars)');
      throw ArgumentError('Project ID cannot exceed 100 characters');
    }
    
    // Validate metadata if provided
    if (metadata != null) {
      _validateMetadata(metadata);
    }
    
    return PntaFlutterPlatform.instance.updateMetadata(projectId.trim(), metadata);
  }
  
  static void _validateMetadata(Map<String, dynamic> metadata) {
    if (metadata.length > 50) {
      debugPrint('PNTA: Invalid metadata - too many keys (${metadata.length})');
      throw ArgumentError('Metadata cannot have more than 50 keys');
    }
    
    for (final entry in metadata.entries) {
      if (entry.key.length > 100) {
        debugPrint('PNTA: Invalid metadata key - too long: ${entry.key}');
        throw ArgumentError('Metadata key "${entry.key}" cannot exceed 100 characters');
      }
      
      if (entry.value is String && (entry.value as String).length > 1000) {
        debugPrint('PNTA: Invalid metadata value - too long for key: ${entry.key}');
        throw ArgumentError('Metadata value for "${entry.key}" cannot exceed 1000 characters');
      }
    }
  }
}
