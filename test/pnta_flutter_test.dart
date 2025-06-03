import 'package:flutter_test/flutter_test.dart';
import 'package:pnta_flutter/pnta_flutter.dart';
import 'package:pnta_flutter/pnta_flutter_platform_interface.dart';
import 'package:pnta_flutter/pnta_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPntaFlutterPlatform
    with MockPlatformInterfaceMixin
    implements PntaFlutterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PntaFlutterPlatform initialPlatform = PntaFlutterPlatform.instance;

  test('$MethodChannelPntaFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPntaFlutter>());
  });

  test('getPlatformVersion', () async {
    PntaFlutter pntaFlutterPlugin = PntaFlutter();
    MockPntaFlutterPlatform fakePlatform = MockPntaFlutterPlatform();
    PntaFlutterPlatform.instance = fakePlatform;

    expect(await pntaFlutterPlugin.getPlatformVersion(), '42');
  });
}
