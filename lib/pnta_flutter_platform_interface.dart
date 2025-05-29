import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pnta_flutter_method_channel.dart';

abstract class PntaFlutterPlatform extends PlatformInterface {
  /// Constructs a PntaFlutterPlatform.
  PntaFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static PntaFlutterPlatform _instance = MethodChannelPntaFlutter();

  /// The default instance of [PntaFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelPntaFlutter].
  static PntaFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PntaFlutterPlatform] when
  /// they register themselves.
  static set instance(PntaFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> requestNotificationPermission() {
    throw UnimplementedError('requestNotificationPermission() has not been implemented.');
  }

  Future<String?> getDeviceToken() {
    throw UnimplementedError('getDeviceToken() has not been implemented.');
  }
}
