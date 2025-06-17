import 'package:flutter/material.dart';
import 'package:pnta_flutter/pnta_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PntaFlutter.navigatorKey,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _deviceToken;
  String? _lastNotificationTap;
  String? _foregroundLink;
  final List<Map<String, dynamic>> _foregroundNotifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPnta();
    PntaFlutter.foregroundNotifications.listen((payload) {
      setState(() {
        _foregroundNotifications.insert(0, payload);
        final link = payload['link_to'] as String?;
        if (link != null && link.isNotEmpty) {
          _foregroundLink = link;
        }
      });
    });
    PntaFlutter.onNotificationTap.listen((payload) {
      setState(() {
        _lastNotificationTap = payload.toString();
      });
    });
  }

  Future<void> _initPnta() async {
    await PntaFlutter.initialize(
      'prj_k3e0Givq',
      metadata: {
        'user_id': '123',
        'email': 'user@example.com',
        'role': 'tester',
      },
      autoHandleLinks: false, // We'll handle links manually for demo
    );
    setState(() {
      _deviceToken = PntaFlutter.deviceToken;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PNTA Metadata & Foreground Demo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Device Token:'),
                  SelectableText(_deviceToken ?? 'No token (denied or error)'),
                  const SizedBox(height: 24),
                  const Text('Foreground Notifications:'),
                  if (_foregroundNotifications.isEmpty) const Text('None'),
                  for (final notif in _foregroundNotifications)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(notif.toString()),
                      ),
                    ),
                  const SizedBox(height: 24),
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
                  const Text('Last Notification Tap Payload:'),
                  SelectableText(_lastNotificationTap ?? 'None'),
                ],
              ),
      ),
    );
  }
}
