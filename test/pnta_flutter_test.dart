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
  Future<bool> checkNotificationPermission() => Future.value(true);

  @override
  Future<String?> getDeviceToken() => Future.value('mock_token');

  @override
  Future<String?> identify(String projectId) => Future.value('mock_user_id');

  @override
  Future<void> updateMetadata(
    String projectId, [
    Map<String, dynamic>? metadata,
  ]) =>
      Future.value();

  String? lastTrackOpenProjectId;
  String? lastTrackOpenNotificationId;
  String? lastTrackOpenToken;

  @override
  Future<void> trackOpen(
      String projectId, String notificationId, String token) {
    lastTrackOpenProjectId = projectId;
    lastTrackOpenNotificationId = notificationId;
    lastTrackOpenToken = token;
    return Future.value();
  }

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

  test('deviceToken getter', () async {
    MockPntaFlutterPlatform fakePlatform = MockPntaFlutterPlatform();
    PntaFlutterPlatform.instance = fakePlatform;

    // Test that deviceToken is accessible via getter
    expect(PntaFlutter.deviceToken, isNull); // Initially null
  });

  test('trackOpen pulls notification_id and token from the payload', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final fakePlatform = MockPntaFlutterPlatform();
    PntaFlutterPlatform.instance = fakePlatform;

    await PntaFlutter.initialize('prj_test');
    await PntaFlutter.trackOpen(
        {'notification_id': 'notif_abc', 'token': 'tok_123'});

    expect(fakePlatform.lastTrackOpenProjectId, 'prj_test');
    expect(fakePlatform.lastTrackOpenNotificationId, 'notif_abc');
    expect(fakePlatform.lastTrackOpenToken, 'tok_123');
  });
}
