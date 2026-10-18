## 1.3.0

-   Track notification opens automatically when a notification is tapped, once per tap
-   Remove `trackOpen`: opens are now tracked by the SDK, so delete any `PntaFlutter.trackOpen(...)` calls when upgrading
-   Deliver the notification that launched the app to the first `onNotificationTap` listener
-   Handle links from `autoHandleLinks` once per tap instead of once per listener
-   Taps are only delivered after `initialize()` has been called
-   Ignore a missing or non-string `link_to` instead of throwing

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