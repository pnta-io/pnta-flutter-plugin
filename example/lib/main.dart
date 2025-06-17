import 'package:flutter/material.dart';
import 'package:pnta_flutter/pnta_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PntaFlutter.navigatorKey,
      home: HomePage(),
      routes: {
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _initialized = false;
  String? _lastNotification;

  @override
  void initState() {
    super.initState();
    _initialize();
    _setupNotificationListeners();
  }

  Future<void> _initialize() async {
    await PntaFlutter.initialize(
      'prj_k3e0Givq', // replace with your project id
      metadata: {
        'user_id': '123',
        'email': 'user@example.com',
        'role': 'demo_user',
      },
      autoHandleLinks: true,
      showSystemUI: true,
    );
    setState(() => _initialized = true);
  }

  void _setupNotificationListeners() {
    PntaFlutter.foregroundNotifications.listen((notification) {
      setState(() {
        _lastNotification = 'Received: ${notification.toString()}';
      });
    });

    PntaFlutter.onNotificationTap.listen((notification) {
      setState(() {
        _lastNotification = 'Tapped: ${notification.toString()}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PNTA Example')),
      body: Center(
        child: _initialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Push notifications ready!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text('Device token: ${PntaFlutter.deviceToken != null ? "Available" : "Not available"}'),
                  SizedBox(height: 16),
                  if (PntaFlutter.deviceToken != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: SelectableText(
                        PntaFlutter.deviceToken!,
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: 24),
                  Text('Last notification:'),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      _lastNotification ?? 'No notifications yet',
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Center(
        child: Text('Profile page opened via deep link!'),
      ),
    );
  }
}