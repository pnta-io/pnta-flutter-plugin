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

-   **Info.plist:** (Recommended) Add a usage description for notifications:

```xml
<key>NSUserNotificationUsageDescription</key>
<string>This app would like to send you notifications.</string>
```

#### Android

-   **AndroidManifest.xml:** Add the notification permission (required for Android 13+):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

## Example

See the `example/` app for a working usage example.
