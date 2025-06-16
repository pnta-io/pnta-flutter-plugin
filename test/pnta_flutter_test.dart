import 'package:flutter_test/flutter_test.dart';
import 'package:pnta_flutter/pnta_flutter.dart';
import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';
import 'package:pnta_flutter/pnta_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPntaFlutterPlatform
    with MockPlatformInterfaceMixin
    implements PntaFlutterPlatform {
  @override
  Future<bool> requestNotificationPermission() => Future.value(true);

  @override
  Future<String?> getDeviceToken() => Future.value('mock_token');

  @override
  Future<String?> identify(String projectId,
          {Map<String, dynamic>? metadata}) =>
      Future.value('mock_user_id');

  @override
  Future<void> updateMetadata(String projectId,
          [Map<String, dynamic>? metadata]) =>
      Future.value();

  @override
  Stream<Map<String, dynamic>> get foregroundNotifications => Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onNotificationTap => Stream.empty();

  @override
  Future<void> setForegroundPresentationOptions({required bool showSystemUI}) =>
      Future.value();
}

void main() {
  final PntaFlutterPlatform initialPlatform = PntaFlutterPlatform.instance;

  test('$MethodChannelPntaFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPntaFlutter>());
  });

  test('getDeviceToken', () async {
    MockPntaFlutterPlatform fakePlatform = MockPntaFlutterPlatform();
    PntaFlutterPlatform.instance = fakePlatform;

    expect(await PntaFlutter.getDeviceToken(), 'mock_token');
  });
}
