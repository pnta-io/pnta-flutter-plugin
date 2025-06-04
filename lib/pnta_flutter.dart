import 'package:flutter/material.dart';
import 'src/permission.dart';
import 'src/token.dart';
import 'src/identify.dart';
import 'src/foreground.dart';
import 'src/link_handler.dart';
import 'src/metadata.dart';

class PntaFlutter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(); // Used globally, including by LinkHandler

  /// Call once to initialize the plugin and enable features.
  static Future<void> initialize(
      {bool autoHandleLinks = false, bool showSystemUI = false}) async {
    LinkHandler.initialize(autoHandleLinks: autoHandleLinks);
    await setForegroundPresentationOptions(showSystemUI: showSystemUI);
  }

  /// Emits notification payloads when received while the app is in the foreground.
  static Stream<Map<String, dynamic>> get foregroundNotifications =>
      _foregroundNotificationsStream();

  /// Emits notification payloads when the user taps a notification (background/tap event).
  static Stream<Map<String, dynamic>> get onNotificationTap =>
      _onNotificationTapStream();

  static Stream<Map<String, dynamic>> _foregroundNotificationsStream() async* {
    await for (final payload in foregroundNotificationsStream) {
      yield payload;
    }
  }

  static Stream<Map<String, dynamic>> _onNotificationTapStream() async* {
    await for (final payload in onNotificationTapStream) {
      if (LinkHandler.autoHandleLinks) {
        await LinkHandler.handleLink(payload['link_to'] as String?);
      }
      yield payload;
    }
  }

  static Future<bool> requestNotificationPermission() {
    return Permission.requestNotificationPermission();
  }

  static Future<String?> getDeviceToken() {
    return Token.getDeviceToken();
  }

  static Future<void> identify(String projectId, String deviceToken, {Map<String, dynamic>? metadata}) {
    return Identify.identify(projectId, deviceToken, metadata: metadata);
  }

  /// Configures whether the native system UI should be shown for foreground notifications.
  static Future<void> setForegroundPresentationOptions(
      {required bool showSystemUI}) {
    return setForegroundPresentationOptionsInternal(showSystemUI: showSystemUI);
  }

  static Future<void> handleLink(String link) => LinkHandler.handleLink(link);

  static Future<void> updateMetadata(String projectId, {Map<String, dynamic>? metadata}) async {
    final token = await getDeviceToken();
    if (token == null) throw Exception('Device token not available');
    return Metadata.updateMetadata(projectId, metadata: metadata);
  }
}
