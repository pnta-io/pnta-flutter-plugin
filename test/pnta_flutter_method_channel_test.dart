import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pnta_flutter/pnta_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelPntaFlutter platform = MethodChannelPntaFlutter();
  const MethodChannel channel = MethodChannel('pnta_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getDeviceToken', () async {
    expect(await platform.getDeviceToken(), '42');
  });
}
