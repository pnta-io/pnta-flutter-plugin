import 'package:flutter/material.dart';
import 'package:pnta_flutter/pnta_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PntaFlutter.initialize(
    'prj_k3e0Givq', // replace with your project id
    metadata: {
      'user_id': '123',
      'user_email': 'user@example.com',
    },
    autoHandleLinks: true,
    showSystemUI: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _lastNotification;

  @override
  void initState() {
    super.initState();

    PntaFlutter.foregroundNotifications.listen((payload) {
      setState(() => _lastNotification = 'Foreground: ${payload.toString()}');
    });

    PntaFlutter.onNotificationTap.listen((payload) {
      setState(() => _lastNotification = 'Tap: ${payload.toString()}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PNTA Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Push notifications ready!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
                'Device token: ${PntaFlutter.deviceToken != null ? "Available" : "Not available"}'),
            if (PntaFlutter.deviceToken != null)
              SelectableText(
                PntaFlutter.deviceToken!,
                style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            if (_lastNotification != null) ...[
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: SelectableText(
                  _lastNotification!,
                  style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
