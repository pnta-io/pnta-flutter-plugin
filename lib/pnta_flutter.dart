import 'package:flutter/material.dart';
import 'src/permission.dart';
import 'src/token.dart';
import 'src/identify.dart';
import 'src/foreground.dart';
import 'src/link_handler.dart';
import 'src/metadata.dart';

class PntaFlutter {
  static String? _projectId;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ==================== INITIALIZATION ====================

  /// Call once to initialize the plugin and enable features.
  static Future<void> initialize(String projectId,
      {bool autoHandleLinks = false, bool showSystemUI = false}) async {
    _projectId = projectId;
    LinkHandler.initialize(autoHandleLinks: autoHandleLinks);
    await setForegroundPresentationOptions(showSystemUI: showSystemUI);
  }

  // ==================== NOTIFICATIONS ====================

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

  /// Configures whether the native system UI should be shown for foreground notifications.
  static Future<void> setForegroundPresentationOptions(
      {required bool showSystemUI}) {
    return setForegroundPresentationOptionsInternal(showSystemUI: showSystemUI);
  }

  // ==================== PERMISSIONS & TOKEN ====================

  static Future<bool> requestNotificationPermission() {
    return Permission.requestNotificationPermission();
  }

  static Future<String?> getDeviceToken() {
    return Token.getDeviceToken();
  }

  // ==================== USER IDENTIFICATION ====================

  static Future<String?> identify({Map<String, dynamic>? metadata}) {
    if (_projectId == null) {
      throw StateError(
          'PNTA must be initialized with a project ID before calling identify');
    }
    return Identify.identify(_projectId!, metadata: metadata);
  }

  static Future<void> updateMetadata({Map<String, dynamic>? metadata}) {
    if (_projectId == null) {
      throw StateError(
          'PNTA must be initialized with a project ID before calling updateMetadata');
    }
    return Metadata.updateMetadata(_projectId!, metadata: metadata);
  }

  // ==================== LINK HANDLING ====================

  static Future<void> handleLink(String link) => LinkHandler.handleLink(link);
}
