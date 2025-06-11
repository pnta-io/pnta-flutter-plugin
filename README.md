# PNTA Flutter Plugin

A Flutter plugin for requesting push notification permissions and handling notifications on iOS and Android with deep linking support.

## Requirements

- iOS 12.0+
- Android API 21+ 
- Flutter 3.3.0+

## Table of Contents

-   [Installation & Setup](#installation--setup)
    -   [iOS Setup](#ios-setup)
    -   [Android Setup](#android-setup)
-   [Quick Start Guide](#quick-start-guide)
-   [API Reference](#api-reference)
-   [Simple Example](#simple-example)
-   [Troubleshooting](#troubleshooting)

## Installation & Setup

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
    pnta_flutter: ^latest_version
```

Then run:

```bash
flutter pub get
```

### iOS Setup

#### 1. Xcode Configuration

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your app target and go to "Signing & Capabilities"
3. Add "Push Notifications" capability
4. Add "Background Modes" capability and enable "Remote notifications"

Your `ios/Runner/Info.plist` should include:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

#### 2. Podfile Configuration

Update your `ios/Podfile` with the following configuration:

```ruby
def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. Run `flutter pub get` first."
  end
  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found. Try deleting Generated.xcconfig and re-running `flutter pub get`"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

### Android Setup

#### 1. Firebase Configuration

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Register your Android app using your package name (e.g., `com.example.your_app`)
4. Download `google-services.json` and place it at `android/app/google-services.json`

#### 2. Gradle Configuration

**Project-level `android/build.gradle`:**
Add to the `buildscript { dependencies { ... } }` block:

```gradle
classpath 'com.google.gms:google-services:4.3.15' // or latest version
```

**App-level `android/app/build.gradle`:**
Add at the very bottom:

```gradle
apply plugin: 'com.google.gms.google-services'
```

#### 3. AndroidManifest.xml Updates

Add the following to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- For Android 13+ notification permission -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- For opening external URLs -->
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="http" />
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
</queries>

<application>
  <!-- Default notification channel -->
  <meta-data
      android:name="com.google.firebase.messaging.default_notification_channel_id"
      android:value="pnta_default" />

  <!-- Firebase messaging service -->
  <service
      android:name="io.pnta.pnta_flutter.PntaMessagingService"
      android:exported="false">
    <intent-filter>
      <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
  </service>
</application>
```


## Quick Start Guide

### 1. Initialize the Plugin

Configure the plugin once at app startup:

```dart
import 'package:pnta_flutter/pnta_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PntaFlutter.initialize(
    autoHandleLinks: true,  // Auto-open links from background notifications
    showSystemUI: false,    // Hide system notification UI when app is in foreground
  );

  runApp(MyApp());
}
```

### 2. Setup Navigation Key

Ensure your `MaterialApp` uses the global navigator key for deep linking:

```dart
MaterialApp(
  navigatorKey: PntaFlutter.navigatorKey, // Required for internal route navigation
  // ... rest of your app
)
```

### 3. Request Notification Permission

```dart
final granted = await PntaFlutter.requestNotificationPermission();
if (granted) {
  print('Notification permission granted');
} else {
  print('Notification permission denied');
}
```

### 4. Identify Your Device

Register the device with your PNTA project using your project ID (format: `prj_XXXXXXXXX`). Get your project ID from your project settings at [app.pnta.io](https://app.pnta.io).

There are two ways to call this method:

```dart
// Option 1: Simple identification (device token handled internally)
await PntaFlutter.identify('prj_XXXXXXXXX', metadata: {
  'user_id': '123',
  'user_email': 'user@example.com',
});

// Option 2: Get the device token returned (if you need it for your backend)
final deviceToken = await PntaFlutter.identify('prj_XXXXXXXXX', metadata: {
  'user_id': '123',
  'user_email': 'user@example.com',
});
if (deviceToken != null) {
  print('Device token: $deviceToken');
  // Store or send to your backend if needed
}
```

### 5. Handle Notifications

#### Foreground Notifications

```dart
PntaFlutter.foregroundNotifications.listen((payload) {
  print('Received foreground notification: ${payload['title']}');

  // Show custom UI (snackbar, dialog, etc.)
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${payload['title']}: ${payload['body']}')),
  );

  // Manually handle links if needed
  final link = payload['link_to'] as String?;
  if (link != null && link.isNotEmpty) {
    PntaFlutter.handleLink(link);
  }
});

// Remember to cancel subscriptions in dispose() to avoid memory leaks
```

#### Background/Terminated Notifications

```dart
PntaFlutter.onNotificationTap.listen((payload) {
  print('User tapped notification: ${payload['title']}');

  // Track analytics, show specific screen, etc.
  // Links are auto-handled if autoHandleLinks is true
});

// Remember to cancel subscriptions in dispose() to avoid memory leaks
```

## API Reference

### Core Methods

#### `PntaFlutter.initialize({bool autoHandleLinks, bool showSystemUI})`

Initializes the plugin with configuration options.

-   `autoHandleLinks`: Automatically handle `link_to` URLs when notifications are tapped from background/terminated state
-   `showSystemUI`: Show system notification banner/sound when app is in foreground

#### `PntaFlutter.requestNotificationPermission()`

Requests notification permission from the user. Returns `Future<bool>`.

#### `PntaFlutter.identify(String projectId, {Map<String, dynamic>? metadata})`

Registers the device with your PNTA project. Can be called in two ways:

-   **Without storing token**: `await PntaFlutter.identify(projectId, metadata: {...})`
-   **With token returned**: `final token = await PntaFlutter.identify(projectId, metadata: {...})`

Returns the device token as `Future<String?>` if you need it for your own backend or logging.

#### `PntaFlutter.updateMetadata(String projectId, {Map<String, dynamic>? metadata})`

Updates device metadata without re-registering. Returns `Future<void>`.

#### `PntaFlutter.handleLink(String link)`

Manually handles a link using the plugin's routing logic.

### Properties

#### `PntaFlutter.navigatorKey`

Global navigator key for internal route navigation. Must be assigned to your `MaterialApp`.

#### `PntaFlutter.foregroundNotifications`

Stream of notification payloads received when app is in foreground.

#### `PntaFlutter.onNotificationTap`

Stream of notification payloads when user taps a notification from background/terminated state.

### Link Handling Rules

The plugin automatically routes links based on these rules:

-   **Contains `://`** (e.g., `http://example.com`, `mailto:test@example.com`) → Opens externally via system browser/app
-   **No `://`** (e.g., `/profile`, `/settings`) → Navigates internally using Flutter's Navigator

### Metadata Best Practices

Store your metadata in one place and use it consistently:

```dart
class UserMetadata {
  static Map<String, dynamic> get current => {
    'user_id': getCurrentUserId(),
    'app_version': getAppVersion(),
    'subscription_tier': getSubscriptionTier(),
    'last_active': DateTime.now().toIso8601String(),
  };
}

// Use everywhere
await PntaFlutter.identify('prj_XXXXXXXXX', metadata: UserMetadata.current);
await PntaFlutter.updateMetadata('prj_XXXXXXXXX', metadata: UserMetadata.current);
```

## Simple Example

```dart
import 'package:flutter/material.dart';
import 'package:pnta_flutter/pnta_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize plugin
  await PntaFlutter.initialize(
    autoHandleLinks: true,  // Auto-handle links from background taps
    showSystemUI: false,    // Hide system UI in foreground
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PntaFlutter.navigatorKey, // Required for deep linking
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  void _setupNotifications() async {
    // Request permission
    final granted = await PntaFlutter.requestNotificationPermission();
    if (!granted) return;

    // Identify device
    await PntaFlutter.identify('prj_XXXXXXXXX', metadata: {
      'user_id': '123',
      'user_email': 'user@example.com',
    });

    // Listen for foreground notifications
    PntaFlutter.foregroundNotifications.listen((payload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Received: ${payload['title']}')),
      );
    });

    // Listen for background notification taps
    PntaFlutter.onNotificationTap.listen((payload) {
      print('User tapped notification: ${payload['title']}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PNTA Example')),
      body: Center(child: Text('Ready for notifications!')),
    );
  }
}
```

For a complete working example with all features, see the `example/` app in the plugin repository.

## Troubleshooting

### Common Issues

**Permission not granted on Android:**

-   Ensure `POST_NOTIFICATIONS` permission is in AndroidManifest.xml
-   For Android 13+, permission must be requested at runtime

**Firebase issues:**

-   Verify `google-services.json` is in the correct location
-   Check that Firebase project is properly configured
-   Ensure Google Services plugin is applied

**Deep links not working:**

-   Verify `navigatorKey` is assigned to MaterialApp
-   Check that routes are properly defined
-   For external URLs, ensure `<queries>` block is in AndroidManifest.xml

**iOS build issues:**

-   Clean and rebuild: `flutter clean && flutter pub get`
-   Update Podfile and run `cd ios && pod install`

For more examples and advanced usage, see the `example/` directory in the plugin repository.
