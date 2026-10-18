import 'dart:async';

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

  final List<List<String>> trackedOpens = [];

  @override
  Future<void> trackOpen(
      String projectId, String notificationId, String token) {
    trackedOpens.add([projectId, notificationId, token]);
    return Future.value();
  }

  @override
  Stream<Map<String, dynamic>> get foregroundNotifications => Stream.empty();

  final taps = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onNotificationTap => taps.stream;

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

  group('notification taps', () {
    const tap = {'notification_id': 'notif_tap', 'token': 'tok_tap'};
    late MockPntaFlutterPlatform fakePlatform;

    void listen(void Function(Map<String, dynamic>) onTap) {
      final subscription = PntaFlutter.onNotificationTap.listen(onTap);
      addTearDown(subscription.cancel);
    }

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await PntaFlutter.resetForTesting();
      fakePlatform = MockPntaFlutterPlatform();
      PntaFlutterPlatform.instance = fakePlatform;
    });

    test('tracks the open and delivers the tap', () async {
      await PntaFlutter.initialize('prj_test');
      final received = <Map<String, dynamic>>[];
      listen(received.add);

      fakePlatform.taps.add(tap);
      await pumpEventQueue();

      expect(fakePlatform.trackedOpens, [
        ['prj_test', 'notif_tap', 'tok_tap']
      ]);
      expect(received, [tap]);
    });

    test('tracks one open when there are several listeners', () async {
      await PntaFlutter.initialize('prj_test');
      listen((_) {});
      listen((_) {});

      fakePlatform.taps.add(tap);
      await pumpEventQueue();

      expect(fakePlatform.trackedOpens, hasLength(1));
    });

    test('tracks the open when the app does not listen', () async {
      await PntaFlutter.initialize('prj_test');

      fakePlatform.taps.add(tap);
      await pumpEventQueue();

      expect(fakePlatform.trackedOpens, hasLength(1));
    });

    test('delivers a tap that arrived before the app listened', () async {
      await PntaFlutter.initialize('prj_test');
      fakePlatform.taps.add(tap);
      await pumpEventQueue();

      final received = <Map<String, dynamic>>[];
      listen(received.add);
      await pumpEventQueue();

      expect(received, [tap]);
      expect(fakePlatform.trackedOpens, hasLength(1));
    });

    test('skips tracking when the payload has no valid ids', () async {
      await PntaFlutter.initialize('prj_test');

      fakePlatform.taps.add({'notification_id': 42, 'token': 'tok_tap'});
      await pumpEventQueue();

      expect(fakePlatform.trackedOpens, isEmpty);
    });
  });
}
