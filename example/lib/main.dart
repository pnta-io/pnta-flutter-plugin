import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pnta_flutter/pnta_flutter.dart';

void main() {
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
  final List<Map<String, dynamic>> _foregroundNotifications = [];
  StreamSubscription<Map<String, dynamic>>? _foregroundSub;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _foregroundSub = PntaFlutter.foregroundNotifications.listen((payload) {
      setState(() {
        _foregroundNotifications.insert(0, payload);
      });
    });
    PntaFlutter.setForegroundPresentationOptions(showSystemUI: _showSystemUI);
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                        child: ListTile(
                          title: Text(notif['title']?.toString() ?? 'No title'),
                          subtitle: Text(notif['body']?.toString() ?? notif.toString()),
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
                    const Text('Show System UI for Foreground Notifications'),
                    Switch(
                      value: _showSystemUI,
                      onChanged: (val) {
                        setState(() {
                          _showSystemUI = val;
                        });
                        PntaFlutter.setForegroundPresentationOptions(showSystemUI: val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
