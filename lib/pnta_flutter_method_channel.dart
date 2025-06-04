import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pnta_flutter_platform_interface.dart';

/// An implementation of [PntaFlutterPlatform] that uses method channels.
class MethodChannelPntaFlutter extends PntaFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pnta_flutter');

  final EventChannel _foregroundNotificationsEventChannel =
      const EventChannel('pnta_flutter/foreground_notifications');
  Stream<Map<String, dynamic>>? _foregroundNotificationsStream;

  final EventChannel _notificationTapEventChannel =
      const EventChannel('pnta_flutter/notification_tap');
  Stream<Map<String, dynamic>>? _notificationTapStream;

  @override
  Future<bool> requestNotificationPermission() async {
    final result =
        await methodChannel.invokeMethod<bool>('requestNotificationPermission');
    return result ?? false;
  }

  @override
  Future<String?> getDeviceToken() async {
    final token = await methodChannel.invokeMethod<String>('getDeviceToken');
    return token;
  }

  @override
  Future<void> identify(String projectId, String deviceToken, [Map<String, dynamic>? metadata]) async {
    await methodChannel.invokeMethod('identify', {
      'projectId': projectId,
      'deviceToken': deviceToken,
      if (metadata != null) 'metadata': metadata,
    });
  }

  @override
  Future<void> updateMetadata(String projectId, [Map<String, dynamic>? metadata]) async {
    await methodChannel.invokeMethod('updateMetadata', {
      'projectId': projectId,
      if (metadata != null) 'metadata': metadata,
    });
  }

  @override
  Stream<Map<String, dynamic>> get foregroundNotifications {
    _foregroundNotificationsStream ??= _foregroundNotificationsEventChannel
        .receiveBroadcastStream()
        .map<Map<String, dynamic>>((event) => Map<String, dynamic>.from(event));
    return _foregroundNotificationsStream!;
  }

  @override
  Future<void> setForegroundPresentationOptions(
      {required bool showSystemUI}) async {
    await methodChannel.invokeMethod('setForegroundPresentationOptions', {
      'showSystemUI': showSystemUI,
    });
  }

  @override
  Stream<Map<String, dynamic>> get onNotificationTap {
    _notificationTapStream ??= _notificationTapEventChannel
        .receiveBroadcastStream()
        .map<Map<String, dynamic>>((event) => Map<String, dynamic>.from(event));
    return _notificationTapStream!;
  }
}
