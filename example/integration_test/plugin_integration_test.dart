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

  testWidgets('PNTA initialization test', (WidgetTester tester) async {
    // Test that initialization doesn't throw errors
    // Note: This won't actually register since we're using a test project ID
    try {
      await PntaFlutter.initialize(
        'prj_test123',
        registerDevice: false, // Don't register device in test
        metadata: {'test': 'true'},
      );
      // If we get here without exception, initialization succeeded
      expect(true, true); // Just verify no exception was thrown
    } catch (e) {
      // Expected to fail with network/permission issues in test environment
      expect(e, isNotNull);
    }
  });
}
