import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';

/// Emits notification payloads when received while the app is in the foreground.
Stream<Map<String, dynamic>> get foregroundNotificationsStream =>
    PntaFlutterPlatform.instance.foregroundNotifications;

/// Configures whether the native system UI should be shown for foreground notifications.
Future<void> setForegroundPresentationOptionsInternal({required bool showSystemUI}) {
  return PntaFlutterPlatform.instance.setForegroundPresentationOptions(showSystemUI: showSystemUI);
} 