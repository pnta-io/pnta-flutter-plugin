import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pnta_flutter/pnta_flutter.dart';
import 'dart:convert';

/*
Example: Using pnta_flutter for Push Notifications & Deep Linking

This example demonstrates both the minimal required setup and additional showcase features for debugging and demonstration.

====================
REQUIRED FOR FEATURES TO WORK:
====================
- Initialize the plugin
- Request notification permissions
- Obtain and register a device token
- Identify the device with your project/user (REQUIRED)
- (Optional) Listen to onNotificationTap to handle notification taps (for navigation or logic)

====================
SHOWCASE/DEMO ONLY (NOT REQUIRED):
====================
- UI for displaying notification payloads, device token, errors, etc.
- Foreground notification listener (for showing notifications while app is open)
- Switches and buttons for toggling plugin options
- Any UI elements for debugging or demonstration

====================
AUTO HANDLE LINKS BEHAVIOR:
====================
- If autoHandleLinks: false (default):
    - You must handle navigation yourself in the onNotificationTap listener for ALL app states (foreground, background, or terminated).
- If autoHandleLinks: true:
    - The plugin will automatically handle navigation for background/terminated notification taps (no Dart code needed for navigation in those cases).
    - You only need to handle navigation for foreground notifications in your Dart code if desired.

====================
Minimal production usage (no UI required):
====================

// --- Option 1: Handle navigation for ALL notification taps yourself (default) ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PntaFlutter.initialize(); // autoHandleLinks: false is default, you handle navigation for all taps
  await PntaFlutter.requestNotificationPermission();
  final token = await PntaFlutter.getDeviceToken();
  await PntaFlutter.identify('your_project_id', token); // REQUIRED

  // Handle navigation or logic here for ALL app states (foreground, background, or terminated)
  PntaFlutter.onNotificationTap.listen((payload) {
    // Handle navigation or logic here
  });

  runApp(MyApp());
}

// --- Option 2: Let the plugin handle navigation for background/terminated taps ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PntaFlutter.initialize(autoHandleLinks: true); // plugin handles navigation for background/terminated taps
  await PntaFlutter.requestNotificationPermission();
  final token = await PntaFlutter.getDeviceToken();
  await PntaFlutter.identify('your_project_id', token); // REQUIRED

  // (Optional) Handle navigation or logic for foreground notification taps only
  PntaFlutter.onNotificationTap.listen((payload) {
    // Handle navigation or logic here for foreground taps if needed
  });

  runApp(MyApp());
}

// See below for advanced/optional features and showcase UI.
*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the plugin. You can customize options below (optional).
  await PntaFlutter.initialize(
    autoHandleLinks: false, // Optional: Enable automatic deep link handling
    showSystemUI:
        false, // Optional: Show system UI for foreground notifications
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // --- State variables ---
  String _notificationStatus = 'Unknown';
  String? _deviceToken;
  String? _tokenError;
  String? _identifyStatus;
  final String _projectId = 'prj_k3e0Givq'; // Replace with your project ID
  bool _showSystemUI = false;
  bool _autoHandleLinks = false;
  final List<Map<String, dynamic>> _foregroundNotifications = [];
  StreamSubscription<Map<String, dynamic>>? _foregroundSub;
  StreamSubscription<Map<String, dynamic>>? _tapSub;
  String? _lastTappedPayload;
  String? _foregroundLink;
  // For demo: show when custom Dart code handles navigation from a notification tap
  String? _customHandledLink;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    // --- OPTIONAL: Listen for foreground notifications ---
    _foregroundSub = PntaFlutter.foregroundNotifications.listen((payload) {
      setState(() {
        _foregroundNotifications.insert(0, payload);
        final link = payload['link_to'] as String?;
        if (link != null && link.isNotEmpty) {
          _foregroundLink = link;
        }
      });
    });
    // --- OPTIONAL: Listen for notification taps (background/terminated/foreground) ---
    _tapSub = PntaFlutter.onNotificationTap.listen((payload) async {
      setState(() {
        _lastTappedPayload =
            const JsonEncoder.withIndent('  ').convert(payload);
      });
      // --- IMPORTANT: ---
      // The following block is ONLY needed if autoHandleLinks is OFF (default):
      //   - You must handle navigation for background/terminated/foreground notification taps yourself.
      //   - If autoHandleLinks is ON, the plugin will handle navigation for background/terminated taps automatically.
      //   - You may still use this listener for analytics, logging, or custom UI in any case.
      final link = payload['link_to'] as String?;
      if (link != null && link.isNotEmpty && !_autoHandleLinks) {
        setState(() {
          _customHandledLink = link;
        });
        // For demo: show a SnackBar if context is available
        final ctx = PntaFlutter.navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
                content: Text('Custom Dart code handled navigation to: $link')),
          );
        }
        await PntaFlutter.handleLink(link);
      }
    });
    _initializePlugin();
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _tapSub?.cancel();
    super.dispose();
  }

  /// Requests notification permission from the user (required for push notifications).
  Future<void> _requestPermission() async {
    bool notificationGranted = false;
    try {
      notificationGranted = await PntaFlutter.requestNotificationPermission();
    } on PlatformException {
      notificationGranted = false;
    }
    if (!mounted) return;
    setState(() {
      _notificationStatus = notificationGranted ? 'Granted' : 'Denied';
    });
    if (notificationGranted) {
      _getDeviceToken();
    }
  }

  /// Obtains the device token and registers it with your project (required for push notifications).
  Future<void> _getDeviceToken() async {
    setState(() {
      _deviceToken = null;
      _tokenError = null;
      _identifyStatus = null;
    });
    try {
      final token = await PntaFlutter.getDeviceToken();
      setState(() {
        _deviceToken = token;
      });
      if (token != null) {
        try {
          await PntaFlutter.identify(_projectId, token);
          setState(() {
            _identifyStatus = 'Identify sent successfully';
          });
        } catch (e) {
          setState(() {
            _identifyStatus = 'Identify failed: $e';
          });
        }
      }
    } catch (e) {
      setState(() {
        _tokenError = e.toString();
      });
    }
  }

  /// (Re)initializes the plugin with the current options (optional, for toggling features).
  Future<void> _initializePlugin() async {
    await PntaFlutter.initialize(
      autoHandleLinks: _autoHandleLinks,
      showSystemUI: _showSystemUI,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PntaFlutter.navigatorKey, // Required for deep linking
      routes: {
        '/': (context) => _buildHome(context),
        '/deep-link': (context) => const DeepLinkScreen(),
      },
    );
  }

  /// Builds the main UI, showing notification status, device token, and controls for optional features.
  Widget _buildHome(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- REQUIRED: Notification permission status ---
              Text('Notification permission: $_notificationStatus'),
              const SizedBox(height: 24),
              // --- OPTIONAL: Foreground notifications ---
              if (_foregroundNotifications.isNotEmpty) ...[
                const Text('Foreground Notifications:'),
                const SizedBox(height: 8),
                ..._foregroundNotifications.map((notif) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ').convert(notif),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    )),
                const SizedBox(height: 24),
              ],
              // --- REQUIRED: Device token and identify status ---
              if (_deviceToken != null) ...[
                const Text('Device Token:'),
                SelectableText(_deviceToken!),
                if (_identifyStatus != null) ...[
                  const SizedBox(height: 16),
                  Text(_identifyStatus!),
                ],
              ],
              if (_tokenError != null) ...[
                const Text('Error fetching token:'),
                SelectableText(_tokenError!),
              ],
              const SizedBox(height: 24),
              // --- OPTIONAL: Feature toggles ---
              Column(
                children: [
                  const Text('Enable link_to auto handling'),
                  Switch(
                    value: _autoHandleLinks,
                    onChanged: (val) async {
                      setState(() {
                        _autoHandleLinks = val;
                      });
                      await _initializePlugin();
                    },
                  ),
                  const Text('Show System UI for Foreground Notifications'),
                  Switch(
                    value: _showSystemUI,
                    onChanged: (val) async {
                      setState(() {
                        _showSystemUI = val;
                      });
                      await PntaFlutter.setForegroundPresentationOptions(
                          showSystemUI: val);
                      await _initializePlugin();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // --- OPTIONAL: Last notification tap payload ---
              if (_lastTappedPayload != null) ...[
                const Text('Last notification tap payload:'),
                SelectableText(_lastTappedPayload!),
                const SizedBox(height: 24),
              ],
              // --- OPTIONAL: Show when custom Dart code handled navigation ---
              if (_customHandledLink != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Custom Dart code handled navigation to: $_customHandledLink',
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              // --- OPTIONAL: Foreground link button ---
              // This button is only for links received while the app is in the foreground.
              if (_foregroundLink != null) ...[
                ElevatedButton(
                  onPressed: () async {
                    final link = _foregroundLink;
                    if (link != null) {
                      await PntaFlutter.handleLink(link);
                      setState(() {
                        _foregroundLink = null;
                      });
                    }
                  },
                  child: const Text('Open Foreground Link (foreground only)'),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Example screen for deep link navigation (optional)
class DeepLinkScreen extends StatelessWidget {
  const DeepLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deep Link Screen')),
      body: const Center(child: Text('You navigated via a deep link!')),
    );
  }
}
