# PNTA Flutter Plugin

[![pub package](https://img.shields.io/pub/v/pnta_flutter.svg)](https://pub.dev/packages/pnta_flutter)

A Flutter plugin for requesting push notification permissions and handling notifications on iOS and Android with deep linking support.

📖 **[Full Documentation](https://docs.pnta.io)** | 🌐 **[PNTA Dashboard](https://app.pnta.io)**

## Requirements

-   iOS 12.0+
-   Android API 21+
-   Flutter 3.3.0+

## Table of Contents

-   [Installation & Setup](#installation--setup)
    -   [iOS Setup](#ios-setup)
    -   [Android Setup](#android-setup)
-   [Quick Start Guide](#quick-start-guide)
-   [API Reference](#api-reference)
-   [Example](#example)

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

#### 2. Plugin Integration

**Automatic!** The plugin integrates automatically when you run:

```bash
flutter pub get
cd ios && pod install
```

**Note:** No manual Podfile configuration needed - Flutter generates the standard Podfile automatically.

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

## Quick Start Guide

### 1. One-Line Setup

The simplest way to get started - this handles everything for most apps:

```dart
import 'package:pnta_flutter/pnta_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One line setup - requests permission and registers device
  await PntaFlutter.initialize(
    'prj_XXXXXXXXX',        // Your project ID from app.pnta.io
    metadata: {
      'user_id': '123',
      'user_email': 'user@example.com',
    },
  );

  // Optional: Get the device token if you need it for your backend
  final deviceToken = PntaFlutter.deviceToken;
  if (deviceToken != null) {
    print('Device token: $deviceToken');
  }

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

### 3. Advanced: Delayed Registration Flow

For apps that need to ask for permission at a specific time (e.g., after user onboarding):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize without registering device, but include metadata for later use
  await PntaFlutter.initialize(
    'prj_XXXXXXXXX',
    registerDevice: false,  // Skip device registration
    metadata: {
      'user_id': '123',
      'user_email': 'user@example.com',
    },
  );

  runApp(MyApp());
}

// Later in your app, when ready to register:
Future<void> setupNotifications() async {
  await PntaFlutter.registerDevice();

  // Optional: Get the device token if you need it for your backend
  final deviceToken = PntaFlutter.deviceToken;
  if (deviceToken != null) {
    print('Device registered successfully! Token: $deviceToken');
  } else {
    print('Registration failed or not completed yet');
  }
}
```

### 4. Handle Notifications

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


```

#### Background/Terminated Notifications

```dart
PntaFlutter.onNotificationTap.listen((payload) {
  print('User tapped notification: ${payload['title']}');

  // Track analytics, show specific screen, etc.
  // Links are auto-handled if autoHandleLinks is true
});


```

## API Reference

### Core Methods

#### `PntaFlutter.initialize(String projectId, {Map<String, dynamic>? metadata, bool registerDevice, bool autoHandleLinks, bool showSystemUI})`

Main initialization method that handles everything for most apps:

-   `projectId`: Your PNTA project ID (format: `prj_XXXXXXXXX`) from [app.pnta.io](https://app.pnta.io)
-   `metadata`: Optional device metadata to include during registration
-   `registerDevice`: Whether to register device immediately (default: `true`)
-   `autoHandleLinks`: Automatically handle `link_to` URLs when notifications are tapped (default: `false`)
-   `showSystemUI`: Show system notification banner/sound when app is in foreground (default: `false`)

Returns `Future<void>`. Use `PntaFlutter.deviceToken` getter to access the device token after successful registration.

#### `PntaFlutter.registerDevice()`

For delayed registration scenarios. Requests notification permission and registers device using metadata from `initialize()`. Must be called after `initialize()` with `registerDevice: false`.

Returns `Future<void>`. Use `PntaFlutter.deviceToken` getter to access the device token after successful registration.

#### `PntaFlutter.updateMetadata(Map<String, dynamic> metadata)`

Updates device metadata without re-registering. Must be called after successful initialization. Returns `Future<void>`.

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

## Example

For a complete working example with all features, see the `example/` app in the plugin repository.
