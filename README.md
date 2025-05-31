# PNTA Flutter Plugin

A Flutter plugin for requesting push notification permissions on iOS and Android.

## Usage

### 1. Add Dependency

Add this plugin to your `pubspec.yaml`:

```yaml
dependencies:
    pnta_flutter:
        path: ../pnta_flutter # or your published version
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

### 3. Platform-specific Setup

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

### 4. Get Device Token

Retrieve the device push notification token (APNs on iOS, FCM on Android):

```dart
final token = await PntaFlutter.getDeviceToken();
if (token != null) {
  // Use the token for identification or backend registration
}
```

### 5. Identify Device

Send device and app metadata to the backend for identification:

```dart
await PntaFlutter.identify(projectId, deviceToken);
```

-   `projectId`: Your PNTA project ID
-   `deviceToken`: The push notification token (from `getDeviceToken()`)

This will collect and send the following metadata (with consistent keys across iOS and Android):

-   name
-   model
-   localized_model
-   system_name
-   system_version
-   identifier_for_vendor
-   device_token
-   region_code
-   language_code
-   currency_code
-   current_locale
-   preferred_languages
-   current_time_zone
-   bundle_identifier
-   app_version
-   app_build

The data is sent as a JSON payload to `https://app.pnta.io/api/v1/identification` via PUT request.

### 6. Foreground Notification Handling

This plugin allows you to intercept and handle push notifications when your app is in the foreground, giving you full control over the user experience.

#### Dart API

```dart
// Listen for foreground notifications
PntaFlutter.foregroundNotifications.listen((payload) {
  // Show custom UI, route user, track analytics, etc.
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

## Example

See the `example/` app for a working usage example.
