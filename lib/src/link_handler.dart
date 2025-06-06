import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pnta_flutter.dart';

class LinkHandler {
  static bool _autoHandleLinks = false;

  /// Call this during plugin initialization.
  static void initialize({bool autoHandleLinks = false}) {
    _autoHandleLinks = autoHandleLinks;
  }

  /// Handles a link: opens external URLs or navigates to in-app routes.
  /// Returns true if successful, false otherwise.
  static Future<bool> handleLink(String? link) async {
    if (link == null || link.isEmpty) {
      debugPrint('PNTA: Cannot handle empty or null link');
      return false;
    }
    
    try {
      if (link.contains('://')) {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('PNTA: Successfully launched URL: $link');
          return true;
        } else {
          debugPrint('PNTA: Cannot launch URL - no app available: $link');
          return false;
        }
      } else {
        final navigator = PntaFlutter.navigatorKey.currentState;
        if (navigator != null) {
          navigator.pushNamed(link);
          debugPrint('PNTA: Successfully navigated to route: $link');
          return true;
        } else {
          debugPrint('PNTA: Cannot navigate - no navigator available for route: $link');
          return false;
        }
      }
    } catch (e, st) {
      debugPrint('PNTA: Error handling link "$link": $e\n$st');
      return false;
    }
  }

  static bool get autoHandleLinks => _autoHandleLinks;
}
