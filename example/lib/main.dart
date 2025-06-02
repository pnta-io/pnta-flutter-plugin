import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pnta_flutter/pnta_flutter.dart';
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PntaFlutter.initialize(
    autoHandleLinks: false, // Enable link_to auto handling
    showSystemUI: false,   // Suppress system UI for foreground notifications
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _notificationStatus = 'Unknown';
  String? _deviceToken;
  String? _tokenError;
  String? _identifyStatus;
  final String _projectId = 'prj_k3e0Givq';
  bool _showSystemUI = false;
  bool _autoHandleLinks = false;
  final List<Map<String, dynamic>> _foregroundNotifications = [];
  StreamSubscription<Map<String, dynamic>>? _foregroundSub;
  StreamSubscription<Map<String, dynamic>>? _tapSub;
  String? _lastTappedPayload;
  String? _foregroundLink;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _foregroundSub = PntaFlutter.foregroundNotifications.listen((payload) {
      setState(() {
        _foregroundNotifications.insert(0, payload);
        final link = payload['link_to'] as String?;
        if (link != null && link.isNotEmpty) {
          _foregroundLink = link;
        }
      });
    });
    _tapSub = PntaFlutter.onNotificationTap.listen((payload) {
      setState(() {
        _lastTappedPayload = const JsonEncoder.withIndent('  ').convert(payload);
      });
    });
    _initializePlugin();
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _tapSub?.cancel();
    super.dispose();
  }

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

  Future<void> _initializePlugin() async {
    await PntaFlutter.initialize(
      autoHandleLinks: _autoHandleLinks,
      showSystemUI: _showSystemUI,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PntaFlutter.navigatorKey,
      routes: {
        '/': (context) => _buildHome(context),
        '/deep-link': (context) => const DeepLinkScreen(),
      },
    );
  }

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
              Text('Notification permission: $_notificationStatus'),
              const SizedBox(height: 24),
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
                      await PntaFlutter.setForegroundPresentationOptions(showSystemUI: val);
                      await _initializePlugin();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_lastTappedPayload != null) ...[
                const Text('Last notification tap payload:'),
                SelectableText(_lastTappedPayload!),
                const SizedBox(height: 24),
              ],
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
                  child: const Text('Open Foreground Link'),
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
