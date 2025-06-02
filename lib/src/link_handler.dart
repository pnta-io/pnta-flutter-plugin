import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Global navigation key for in-app navigation. The app must set this up.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LinkHandler {
  static bool _autoHandleLinks = false;

  /// Call this during plugin initialization.
  static void initialize({bool autoHandleLinks = false}) {
    _autoHandleLinks = autoHandleLinks;
  }

  /// Handles a link: opens external URLs or navigates to in-app routes.
  static Future<void> handleLink(String? link) async {
    if (link == null || link.isEmpty) return;
    try {
      if (link.startsWith('http')) {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint('Could not launch URL: $link');
        }
      } else {
        navigatorKey.currentState?.pushNamed(link);
      }
    } catch (e, st) {
      debugPrint('Error handling link_to: $link\n$e\n$st');
    }
  }

  static bool get autoHandleLinks => _autoHandleLinks;
} 