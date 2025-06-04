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

### 4. Foreground Notification Handling

This plugin allows you to intercept and handle push notifications when your app is in the foreground, giving you full control over the user experience.

**Note:** Foreground notifications are always delivered to Dart, and you are responsible for handling any links in the payload. You can use `PntaFlutter.handleLink(link)` to handle links in your foreground notification handler.

#### Dart API

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

// Configure whether to show the system notification UI (banner, sound, badge) in the foreground
await PntaFlutter.setForegroundPresentationOptions(showSystemUI: false); // default is false
```

-   If `showSystemUI` is `false`, the system notification UI is suppressed in the foreground and you can show your own UI.
-   If `showSystemUI` is `true`, the system notification UI is shown as if the app were in the background, and you still receive the payload in Dart.

#### Platform Behavior

| Platform | System UI Option   | Custom In-App UI | Dart Stream | User Flexibility |
| -------- | ------------------ | ---------------- | ----------- | ---------------- |
| iOS      | Yes (configurable) | Yes              | Yes         | Maximum          |
| Android  | Yes (configurable) | Yes              | Yes         | Maximum          |

-   **iOS:** Uses `UNUserNotificationCenterDelegate` to control presentation and always forwards the payload to Dart.
-   **Android:** Uses a custom `FirebaseMessagingService` to intercept foreground messages, show/hide system UI, and forward the payload to Dart.

#### Android Setup

-   Make sure your `AndroidManifest.xml` includes:
    ```xml
    <service
        android:name="io.pnta.pnta_flutter.PntaMessagingService"
        android:exported="false">
        <intent-filter>
            <action android:name="com.google.firebase.MESSAGING_EVENT" />
        </intent-filter>
    </service>
    ```

### Android Notification Channel Setup

For Android 8.0+ (API 26+), you must define a default notification channel for Firebase Cloud Messaging (FCM) background notifications. This ensures notifications are delivered with your desired settings and removes FCM warnings.

Add the following inside your `<application>` tag in `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="pnta_default" />
```

This tells FCM to use the `pnta_default` channel (created automatically by the plugin) for all background notifications.

#### iOS Setup

-   No extra steps required beyond normal plugin integration.

#### Example Usage

```dart
await PntaFlutter.setForegroundPresentationOptions(showSystemUI: false);

PntaFlutter.foregroundNotifications.listen((payload) {
  // Show custom banner, route user, track analytics, etc.
  print('Received foreground notification: $payload');
});
```

### 5. link_to Push Notification Handling (Deep Links & External URLs)

This plugin supports push notifications with a `link_to` field in the payload, enabling deep linking and external URL handling.

-   If the notification is tapped while the app is in the background or terminated, and `autoHandleLinks` is enabled, the plugin will automatically:
    -   Open external URLs (starting with `http` or `https`) in the system browser (using url_launcher).
    -   Navigate to in-app routes (starting with `/` or any other path) using the app's navigator.
-   When the app is in the foreground, the full notification payload is always delivered to Dart via the stream. You are responsible for handling any links or navigation in this case—`autoHandleLinks` does not apply.

**Implementation Note:**

-   All link handling logic is now centralized in `LinkHandler`. The `autoHandleLinks` flag is managed only by `LinkHandler` and is set via `PntaFlutter.initialize(autoHandleLinks: ...)`.
-   `PntaFlutter.onNotificationTap` will automatically handle links if `autoHandleLinks` is enabled, by delegating to `LinkHandler.handleLink`. You can also manually handle links by calling `PntaFlutter.handleLink(link)`.

#### Dart API

```dart
// Call once, e.g. in main()
await PntaFlutter.initialize(
  autoHandleLinks: false, // default: false
  showSystemUI: false,    // default: false
);

// Listen for foreground notifications (always delivered)
PntaFlutter.foregroundNotifications.listen((payload) { ... });

// Listen for notification taps (background/terminated)
PntaFlutter.onNotificationTap.listen((payload) { ... });
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

#### Platform-specific Setup for URL Handling

**Android:**

-   Add the following `<queries>` block to your `AndroidManifest.xml` (as a child of `<manifest>`, before `<application>`):

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

-   This is required for `url_launcher` to work on Android 11+ (API 30+).
-   Make sure a browser is installed and set up on your device/emulator.

**iOS:**

-   No extra setup is required for external URLs. The plugin uses `url_launcher` which works out of the box.
-   For deep links, ensure your app's `MaterialApp` uses the global navigator key:

```dart
MaterialApp(
  navigatorKey: PntaFlutter.navigatorKey,
  // ...
)
```

#### Notes

-   Foreground notifications are always delivered to Dart, regardless of the `autoHandleLinks` setting. You have full control over how to handle them.
-   The `autoHandleLinks` feature only applies when the app is launched or resumed from a notification tap (background/terminated state).
-   If `link_to` is invalid or cannot be handled, an error is logged but the app will not crash.
-   The MainActivity override (see below) is only required for notification tap (background) events on Android. Foreground notifications do not require any MainActivity changes.

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

### 6. Link Handling Rules and Deep Linking

When handling `link_to` payloads, the plugin uses the following rule:

-   **If the link contains `://`** (e.g., `http://`, `mailto://`, `myapp://`), it is treated as an external URI and opened via the OS using `url_launcher` in `LaunchMode.externalApplication`.
-   **Otherwise** (e.g., `/home`, `/profile`), the link is treated as an internal Flutter route and is pushed using the global `navigatorKey`.

#### Important: Deep Linking for Custom Schemes

If you use custom URI schemes (such as `myapp://posts`) in your `link_to` payloads, you must set up deep linking on your platform (Android/iOS) for your app to handle these links. If deep linking is not set up, the OS will attempt to open the link externally, and your app may not receive it.

**If you have not set up deep linking for your custom schemes, use standard internal route names (like `/appointments`) and rely on the `navigatorKey` for in-app navigation.**

-   For more information on deep linking in Flutter, see the [Flutter deep linking documentation](https://docs.flutter.dev/development/ui/navigation/deep-linking).

## Example

See the `example/` app for a working usage example.
