# PNTA Flutter Plugin

A Flutter plugin for requesting push notification permissions on iOS and Android.

## Usage

### 1. Platform-specific Setup

#### iOS

To use this plugin on iOS, make sure your Podfile **includes the following configuration** (you can copy the whole block if starting fresh):

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

This ensures the plugin integrates correctly and Swift support is enabled.

#### Android

To use this plugin on Android, you must complete the following steps:

1. **Add Firebase to Your Android App**

    - Go to the [Firebase Console](https://console.firebase.google.com/).
    - Create a new project (or use an existing one).
    - Register your Android app (use your app's package name, e.g., `com.example.your_app`).
    - Download the `google-services.json` file from the Firebase Console.
    - Place the file in your Flutter project at:
        - `android/app/google-services.json`

2. **Update Your Gradle Files**

    - **Project-level `android/build.gradle`:**
        - Make sure the following is present inside the `buildscript { dependencies { ... } }` block:
            ```gradle
            classpath 'com.google.gms:google-services:4.3.15' // or latest version
            ```
    - **App-level `android/app/build.gradle`:**
        - At the very bottom of the file, add:
            ```gradle
            apply plugin: 'com.google.gms.google-services'
            ```

3. **AndroidManifest.xml:** Add the notification permission (required for Android 13+):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 2. Request Notification Permission

Call this method from your Dart code (e.g., on app launch):

```dart
import 'package:pnta_flutter/pnta_flutter.dart';

final granted = await PntaFlutter.requestNotificationPermission();
if (granted) {
  // Permission granted, proceed with notifications
} else {
  // Permission denied
}
```

### 3. Identify Device & Manage Metadata

Send device and app metadata to the backend for identification and future updates. The device token is handled internally by the plugin and is also returned by the identify call:

```dart
// Best practice: keep your metadata in one place in your app state
final metadata = {
  'user_id': '123',
  'custom_key': 'custom_value',
  // ...any other fields
};

// On first registration/identification (if you don't need the token):
await PntaFlutter.identify(projectId, metadata: metadata);

// Or, if you want the token:
final deviceToken = await PntaFlutter.identify(projectId, metadata: metadata);
if (deviceToken != null) {
  // You can use the deviceToken for your own backend or logging if needed
}

// Later, if you want to update metadata (e.g., after user profile changes)
await PntaFlutter.updateMetadata(projectId, metadata: metadata);
```

-   `projectId`: Your PNTA project ID
-   `metadata`: A map of custom metadata to associate with the device (used in both identify and updateMetadata)

**Best Practice:**

-   Store all relevant metadata in a single place in your app state (e.g., a provider, bloc, or singleton).
-   Pass the same metadata map to both `identify` and `updateMetadata` to keep your PNTA in sync.

### 4. Initialize Plugin Configuration

Configure the plugin once at app startup (e.g., in your `main()` function):

```dart
await PntaFlutter.initialize(
  autoHandleLinks: false, // Auto-handle links when notification tapped (background/terminated)
  showSystemUI: false,    // Show system notification UI in foreground
);
```

**Configuration Options:**

-   `autoHandleLinks`: When `true`, automatically opens `link_to` URLs/routes when notifications are tapped (only applies to background/terminated state)
-   `showSystemUI`: When `true`, shows system notification banner/sound even when app is in foreground

### 5. Handle Notifications

#### Foreground Notifications (App is Active)

Listen for notifications when your app is in the foreground:

```dart
// Listen for foreground notifications
PntaFlutter.foregroundNotifications.listen((payload) {
  // Show custom UI, route user, track analytics, etc.
  final link = payload['link_to'] as String?;
  if (link != null && link.isNotEmpty) {
    // Manually handle the link if desired
    PntaFlutter.handleLink(link);
  }
  print('Received foreground notification: $payload');
});
```

**Note:** Foreground notifications are always delivered to Dart for custom handling. The `showSystemUI` setting (from `initialize()`) controls whether you also see the system notification banner.

#### Background Notifications (App in Background/Terminated)

Listen for notification taps when your app is not active:

```dart
// Listen for notification taps (background/terminated)
PntaFlutter.onNotificationTap.listen((payload) {
  // Handle the tap - called when user taps notification
  print('User tapped notification: $payload');

  // If autoHandleLinks is false, manually handle links:
  final link = payload['link_to'] as String?;
  if (link != null) {
    PntaFlutter.handleLink(link);
  }
});
```

**Automatic Link Handling:**
If `autoHandleLinks` was set to `true` in `initialize()`, the plugin automatically:

-   Opens external URLs (`http://`, `https://`) in system browser
-   Navigates to app routes (`/profile`, etc.) using your app's navigator

You can still listen to `onNotificationTap` for analytics or additional logic.

### 6. Link Handling Rules

When handling `link_to` payloads, the plugin uses these rules:

-   **If the link contains `://`** (e.g., `http://`, `mailto://`, `myapp://`), it is treated as an external URI and opened via the OS using `url_launcher`
-   **Otherwise** (e.g., `/home`, `/profile`), the link is treated as an internal Flutter route and is pushed using the global `navigatorKey`

#### Setup Requirements

**For internal routes:**
Ensure your app's `MaterialApp` uses the global navigator key:

```dart
MaterialApp(
  navigatorKey: PntaFlutter.navigatorKey,
  // ...
)
```

**For external URLs on Android:**
Add the following `<queries>` block to your `AndroidManifest.xml`:

```xml
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
```

#### Example Notification Payload

```json
{
    "to": "<device_token>",
    "data": {
        "title": "Test Link",
        "body": "Tap to open a deep link!",
        "link_to": "/deep-link"
    }
}
```

#### Platform-specific Setup

**Android:**
Make sure your `AndroidManifest.xml` includes:

```xml
<service
    android:name="io.pnta.pnta_flutter.PntaMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

**Android Notification Channel:**
Add inside your `<application>` tag:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="pnta_default" />
```

**MainActivity Override (Android):**
For notification tap handling, update your `MainActivity.kt`:

```kotlin
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.pnta.pnta_flutter.NotificationTapHandler

class MainActivity: FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val extras = intent.extras
        if (extras != null && !extras.isEmpty) {
            val payload = mutableMapOf<String, Any>()
            for (key in extras.keySet()) {
                val value = extras.get(key)
                when (value) {
                    is String, is Int, is Boolean, is Double, is Float, is Long -> payload[key] = value
                    else -> payload[key] = value.toString()
                }
            }
            if (payload.isNotEmpty()) {
                NotificationTapHandler.sendTapPayload(payload)
            }
        }
    }
}
```

**iOS:**
No extra setup required beyond normal plugin integration.

### 7. Complete Example

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
    await PntaFlutter.identify('your-project-id', metadata: {
      'user_id': '123',
      'app_version': '1.0.0',
    });

    // Listen for foreground notifications
    PntaFlutter.foregroundNotifications.listen((payload) {
      // Show custom in-app UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Received: ${payload['title']}')),
      );
    });

    // Listen for background notification taps
    PntaFlutter.onNotificationTap.listen((payload) {
      print('User tapped notification: ${payload['title']}');
      // Links are auto-handled if autoHandleLinks is true
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

## Example

See the `example/` app for a working usage example.
