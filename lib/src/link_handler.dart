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
      final uri = Uri.parse(link);
      if (uri.hasScheme) {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) {
          debugPrint('PNTA: Successfully launched URL: $link');
        } else {
          debugPrint('PNTA: Failed to launch URL: $link');
        }
        return launched;
      } else {
        final navigator = PntaFlutter.navigatorKey.currentState;
        if (navigator != null) {
          navigator.pushNamed(link);
          debugPrint('PNTA: Successfully navigated to route: $link');
          return true;
        } else {
          debugPrint(
              'PNTA: Cannot navigate - no navigator available for route: $link');
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
