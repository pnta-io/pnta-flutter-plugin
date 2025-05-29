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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Notification permission: $_notificationStatus'),
            ],
          ),
        ),
      ),
    );
  }
}
