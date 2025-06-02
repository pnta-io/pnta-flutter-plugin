import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'src/permission.dart';
import 'src/token.dart';
import 'src/identify.dart';
import 'src/foreground.dart';

class PntaFlutter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static bool _autoHandleLinks = false;

  /// Call once to initialize the plugin and enable features.
  static Future<void> initialize({bool autoHandleLinks = false, bool showSystemUI = false}) async {
    _autoHandleLinks = autoHandleLinks;
    await setForegroundPresentationOptions(showSystemUI: showSystemUI);
  }

  /// Emits notification payloads when received while the app is in the foreground.
  static Stream<Map<String, dynamic>> get foregroundNotifications => _foregroundNotificationsStream();

  /// Emits notification payloads when the user taps a notification (background/tap event).
  static Stream<Map<String, dynamic>> get onNotificationTap => _onNotificationTapStream();

  static Stream<Map<String, dynamic>> _foregroundNotificationsStream() async* {
    await for (final payload in foregroundNotificationsStream) {
      yield payload;
    }
  }

  static Stream<Map<String, dynamic>> _onNotificationTapStream() async* {
    await for (final payload in onNotificationTapStream) {
      await _maybeHandleLink(payload);
      yield payload;
    }
  }

  static Future<void> _maybeHandleLink(Map<String, dynamic> payload) async {
    if (!_autoHandleLinks) return;
    final link = payload['link_to'] as String?;
    if (link != null && link.isNotEmpty) {
      await _handleLink(link);
    }
  }

  static Future<void> _handleLink(String link) async {
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

  static Future<bool> requestNotificationPermission() {
    return Permission.requestNotificationPermission();
  }

  static Future<String?> getDeviceToken() {
    return Token.getDeviceToken();
  }

  static Future<void> identify(String projectId, String deviceToken) {
    return Identify.identify(projectId, deviceToken);
  }

  /// Configures whether the native system UI should be shown for foreground notifications.
  static Future<void> setForegroundPresentationOptions({required bool showSystemUI}) {
    return setForegroundPresentationOptionsInternal(showSystemUI: showSystemUI);
  }

  static Future<void> handleLink(String link) => _handleLink(link);
}
