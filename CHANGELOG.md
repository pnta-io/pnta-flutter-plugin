## 2.0.0

-   **Breaking:** Remove public `trackOpen`. The SDK now tracks notification opens automatically on tap
-   `onNotificationTap` now delivers taps that arrive before the app listens, such as the tap that launched the app, and handles each link once instead of once per listener
-   `onNotificationTap` only delivers taps after `initialize()` is called
-   A missing or non-string `link_to` is now ignored instead of throwing

## 1.2.0

-   Add trackOpen method for notification open analytics

## 1.1.1

-   Fix build error by removing deprecated PluginRegistry.Registrar import
-   Update Android compileSdkVersion to 35

## 1.1.0

-   Migrate Android Gradle config to plugins { } DSL using Flutter‑recommended approach
-   Standardize payload schema
-   Add PendingIntents and filter out non-notification intents
-   Simplify URL launcher by removing canLaunchUrl check and Android manifest queries

## 1.0.0

-   Initial stable release of PNTA Flutter plugin.