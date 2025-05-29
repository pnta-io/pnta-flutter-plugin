import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pnta_flutter_platform_interface.dart';

/// An implementation of [PntaFlutterPlatform] that uses method channels.
class MethodChannelPntaFlutter extends PntaFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pnta_flutter');

  @override
  Future<bool> requestNotificationPermission() async {
    final result = await methodChannel.invokeMethod<bool>('requestNotificationPermission');
    return result ?? false;
  }

  @override
  Future<String?> getDeviceToken() async {
    final token = await methodChannel.invokeMethod<String>('getDeviceToken');
    return token;
  }

  @override
  Future<void> identify(String projectId, String deviceToken) async {
    await methodChannel.invokeMethod('identify', {
      'projectId': projectId,
      'deviceToken': deviceToken,
    });
  }
}
