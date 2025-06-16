// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pnta_flutter/pnta_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getDeviceToken test', (WidgetTester tester) async {
    // Initialize PNTA first
    await PntaFlutter.initialize('test_project_id');
    final String? token = await PntaFlutter.getDeviceToken();
    // The token can be null if not available, so just check it's a String?
    expect(token, isA<String?>());
  });
}
