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

To use this plugin on iOS, make sure your Podfile includes the following setup.

Replace your `ios/Podfile` contents with:

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

## Example

See the `example/` app for a working usage example.
