import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pnta_flutter_platform_interface.dart';

/// An implementation of [PntaFlutterPlatform] that uses method channels.
class MethodChannelPntaFlutter extends PntaFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pnta_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
