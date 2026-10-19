import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pnta_flutter/pnta_flutter.dart';
import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';
import 'package:pnta_flutter/pnta_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPntaFlutterPlatform
    with MockPlatformInterfaceMixin
    implements PntaFlutterPlatform {
  bool permissionGranted = true;
  bool grantOnRequest = true;
  final List<String> calls = [];
  final List<Map<String, dynamic>?> metadataUpdates = [];

  @override
  Future<bool> requestNotificationPermission() {
    calls.add('requestPermission');
    return Future.value(grantOnRequest);
  }

  @override
  Future<bool> checkNotificationPermission() => Future.value(permissionGranted);

  @override
  Future<String?> getDeviceToken() => Future.value('mock_token');

  @override
  Future<String?> identify(String projectId) {
    calls.add('identify');
    return Future.value('mock_token');
  }

  @override
  Future<void> updateMetadata(
    String projectId, [
    Map<String, dynamic>? metadata,
  ]) {
    metadataUpdates.add(metadata);
    return Future.value();
  }

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

  group('registration', () {
    late MockPntaFlutterPlatform fakePlatform;

    setUp(() async {
      await PntaFlutter.resetForTesting();
      fakePlatform = MockPntaFlutterPlatform();
      PntaFlutterPlatform.instance = fakePlatform;
    });

    test('registers without a prompt when permission is granted', () async {
      await PntaFlutter.initialize('prj_test', registerDevice: false);

      expect(fakePlatform.calls, ['identify']);
      expect(PntaFlutter.deviceToken, 'mock_token');
    });

    test('prompts and registers when permission is not granted', () async {
      fakePlatform.permissionGranted = false;

      await PntaFlutter.initialize('prj_test');

      expect(fakePlatform.calls, ['requestPermission', 'identify']);
      expect(PntaFlutter.deviceToken, 'mock_token');
    });

    test('does not prompt when registerDevice is false', () async {
      fakePlatform.permissionGranted = false;

      await PntaFlutter.initialize('prj_test', registerDevice: false);

      expect(fakePlatform.calls, isEmpty);
      expect(PntaFlutter.deviceToken, isNull);
    });

    test('does not identify when permission is denied', () async {
      fakePlatform.permissionGranted = false;
      fakePlatform.grantOnRequest = false;

      await PntaFlutter.initialize('prj_test');

      expect(fakePlatform.calls, ['requestPermission']);
      expect(PntaFlutter.deviceToken, isNull);
    });

    test('sends metadata after identify', () async {
      await PntaFlutter.initialize('prj_test', metadata: {'plan': 'pro'});

      expect(fakePlatform.metadataUpdates, [
        {'plan': 'pro'}
      ]);
      expect(PntaFlutter.currentMetadata, {'plan': 'pro'});
    });

    test('skips the metadata update when metadata is empty', () async {
      await PntaFlutter.initialize('prj_test', metadata: {});

      expect(fakePlatform.metadataUpdates, isEmpty);
    });

    test('ignores a project id without the prj_ prefix', () async {
      await PntaFlutter.initialize('test');

      expect(PntaFlutter.projectId, isNull);
      expect(fakePlatform.calls, isEmpty);
    });

    test('does nothing before initialize', () async {
      await PntaFlutter.registerDevice();
      await PntaFlutter.updateMetadata({'plan': 'pro'});

      expect(fakePlatform.calls, isEmpty);
      expect(fakePlatform.metadataUpdates, isEmpty);
    });

    test('registerDevice prompts and registers later', () async {
      fakePlatform.permissionGranted = false;
      await PntaFlutter.initialize('prj_test', registerDevice: false);

      await PntaFlutter.registerDevice();

      expect(fakePlatform.calls, ['requestPermission', 'identify']);
      expect(PntaFlutter.deviceToken, 'mock_token');
    });

    test('updateMetadata sends and stores metadata', () async {
      await PntaFlutter.initialize('prj_test');

      await PntaFlutter.updateMetadata({'plan': 'pro'});

      expect(fakePlatform.metadataUpdates, [
        {'plan': 'pro'}
      ]);
      expect(PntaFlutter.currentMetadata, {'plan': 'pro'});
    });
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

    test('delivers a tap with a non-string link', () async {
      await PntaFlutter.initialize('prj_test', autoHandleLinks: true);
      final received = <Map<String, dynamic>>[];
      listen(received.add);

      fakePlatform.taps.add({...tap, 'link_to': 42});
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(fakePlatform.trackedOpens, hasLength(1));
    });
  });
}
