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

  @override
  void initState() {
    super.initState();
    _requestPermission();
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
  }

  Future<void> _getDeviceToken() async {
    setState(() {
      _deviceToken = null;
      _tokenError = null;
    });
    try {
      final token = await PntaFlutter.getDeviceToken();
      setState(() {
        _deviceToken = token;
      });
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
                ElevatedButton(
                  onPressed: _getDeviceToken,
                  child: const Text('Get Device Token'),
                ),
                const SizedBox(height: 16),
                if (_deviceToken != null) ...[
                  const Text('Device Token:'),
                  SelectableText(_deviceToken!),
                ],
                if (_tokenError != null) ...[
                  const Text('Error fetching token:'),
                  SelectableText(_tokenError!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
