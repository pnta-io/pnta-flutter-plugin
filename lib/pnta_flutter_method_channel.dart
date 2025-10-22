import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pnta_flutter_platform_interface.dart';
import 'src/version.dart';

/// An implementation of [PntaFlutterPlatform] that uses method channels.
class MethodChannelPntaFlutter extends PntaFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pnta_flutter');

  final EventChannel _foregroundNotificationsEventChannel = const EventChannel(
    'pnta_flutter/foreground_notifications',
  );
  Stream<Map<String, dynamic>>? _foregroundNotificationsStream;

  final EventChannel _notificationTapEventChannel = const EventChannel(
    'pnta_flutter/notification_tap',
  );
  Stream<Map<String, dynamic>>? _notificationTapStream;

  @override
  Future<bool> requestNotificationPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'requestNotificationPermission',
    );
    return result ?? false;
  }

  @override
  Future<bool> checkNotificationPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'checkNotificationPermission',
    );
    return result ?? false;
  }

  @override
  Future<String?> getDeviceToken() async {
    final token = await methodChannel.invokeMethod<String>('getDeviceToken');
    return token;
  }

  @override
  Future<String?> identify(String projectId) async {
    final token = await methodChannel.invokeMethod<String>('identify', {
      'projectId': projectId,
      'pntaSdkVersion': kPntaSdkVersion,
    });
    return token;
  }

  @override
  Future<void> updateMetadata(
    String projectId, [
    Map<String, dynamic>? metadata,
  ]) async {
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
  Future<void> setForegroundPresentationOptions({
    required bool showSystemUI,
  }) async {
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
