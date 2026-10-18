import 'dart:async';

import 'package:flutter/material.dart';
import 'src/link_handler.dart';
import 'pnta_flutter_platform_interface.dart';

class _PntaFlutterConfig {
  final String projectId;
  final bool autoHandleLinks;
  final bool showSystemUI;
  final bool registerDevice;
  Map<String, dynamic>? metadata;

  _PntaFlutterConfig({
    required this.projectId,
    required this.autoHandleLinks,
    required this.showSystemUI,
    required this.registerDevice,
    this.metadata,
  });
}

class PntaFlutter {
  static _PntaFlutterConfig? _config;
  static String? _deviceToken;
  static StreamSubscription<Map<String, dynamic>>? _tapSubscription;
  static final List<Map<String, dynamic>> _pendingTaps = [];
  static final StreamController<Map<String, dynamic>> _tapController =
      StreamController<Map<String, dynamic>>.broadcast(onListen: () {
    // Deliver taps that arrived before the app subscribed, such as the
    // notification that launched the app.
    final pending = List.of(_pendingTaps);
    _pendingTaps.clear();
    unawaited(_deliverTaps(pending));
  });
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Setup
  /// Main initialization - handles everything for most apps
  static Future<void> initialize(
    String projectId, {
    Map<String, dynamic>? metadata,
    bool registerDevice = true,
    bool autoHandleLinks = false,
    bool showSystemUI = false,
  }) async {
    if (_config != null) {
      debugPrint('PNTA: Already initialized.');
      return;
    }
    try {
      // Validate project ID
      if (!projectId.startsWith('prj_')) {
        debugPrint('PNTA: Invalid project ID. Must start with "prj_".');
        return;
      }
      _config = _PntaFlutterConfig(
        projectId: projectId,
        autoHandleLinks: autoHandleLinks,
        showSystemUI: showSystemUI,
        registerDevice: registerDevice,
        metadata: metadata,
      );
      LinkHandler.initialize(autoHandleLinks: autoHandleLinks);
      _tapSubscription ??=
          PntaFlutterPlatform.instance.onNotificationTap.listen(_onTap);
      await PntaFlutterPlatform.instance.setForegroundPresentationOptions(
        showSystemUI: showSystemUI,
      );

      // Always check if permissions are already granted
      final permissionsGranted =
          await PntaFlutterPlatform.instance.checkNotificationPermission();

      if (permissionsGranted) {
        // Always register if permissions available, regardless of registerDevice flag
        await _performRegistration(metadata: metadata, skipPrompt: true);
      } else if (registerDevice) {
        // Only prompt for permissions if registerDevice: true
        await _performRegistration(metadata: metadata);
      }
    } catch (e, st) {
      debugPrint('PNTA: Initialization error: $e\n$st');
    }
  }

  // Registration
  /// For delayed registration scenarios - prompts for permissions and registers if granted
  static Future<void> registerDevice() async {
    if (_config == null) {
      debugPrint('PNTA: Must call initialize() before registering device.');
      return;
    }
    await _performRegistration(metadata: _config!.metadata);
  }

  /// Update device metadata
  static Future<void> updateMetadata(Map<String, dynamic> metadata) async {
    if (_config == null) {
      debugPrint('PNTA: Must call initialize() before updating metadata.');
      return;
    }
    try {
      await PntaFlutterPlatform.instance.updateMetadata(
        _config!.projectId,
        metadata,
      );
      _config!.metadata = metadata;
    } catch (e, st) {
      debugPrint('PNTA: updateMetadata error: $e\n$st');
    }
  }

  static void _onTap(Map<String, dynamic> payload) {
    unawaited(_trackOpen(payload));
    if (_tapController.hasListener) {
      unawaited(_deliverTaps([payload]));
    } else {
      _pendingTaps.add(payload);
    }
  }

  // Links are handled on delivery, once the app is listening and its
  // navigator is likely mounted.
  static Future<void> _deliverTaps(List<Map<String, dynamic>> payloads) async {
    for (final payload in payloads) {
      if (_config?.autoHandleLinks == true) {
        await handleLink(payload['link_to'] as String?);
      }
      _tapController.add(payload);
    }
  }

  static Future<void> _trackOpen(Map<String, dynamic> payload) async {
    final config = _config;
    if (config == null) return;
    final notificationId = payload['notification_id'];
    final token = payload['token'];
    if (notificationId is! String || token is! String) {
      debugPrint(
          'PNTA: Open not tracked, payload has no notification_id or token.');
      return;
    }
    try {
      await PntaFlutterPlatform.instance.trackOpen(
        config.projectId,
        notificationId,
        token,
      );
    } catch (e, st) {
      debugPrint('PNTA: Error tracking open: $e\n$st');
    }
  }

  // Notifications
  /// Stream of notifications received while app is in foreground
  static Stream<Map<String, dynamic>> get foregroundNotifications =>
      PntaFlutterPlatform.instance.foregroundNotifications;

  /// Stream of notification taps. Opens are tracked automatically.
  static Stream<Map<String, dynamic>> get onNotificationTap =>
      _tapController.stream;

  /// Clears SDK state between tests.
  @visibleForTesting
  static Future<void> resetForTesting() async {
    await _tapSubscription?.cancel();
    _tapSubscription = null;
    _pendingTaps.clear();
    _config = null;
    _deviceToken = null;
  }

  // Utilities
  /// Manually handle a deep link
  static Future<bool> handleLink(String? link) async {
    return await LinkHandler.handleLink(link);
  }

  // Getters
  static String? get projectId => _config?.projectId;
  static bool get autoHandleLinks => _config?.autoHandleLinks ?? false;
  static bool get showSystemUI => _config?.showSystemUI ?? false;
  static Map<String, dynamic>? get currentMetadata => _config?.metadata;
  static String? get deviceToken => _deviceToken;

  // Private
  static Future<void> _performRegistration({
    Map<String, dynamic>? metadata,
    bool skipPrompt = false,
  }) async {
    try {
      final granted = skipPrompt
          ? await PntaFlutterPlatform.instance.checkNotificationPermission()
          : await PntaFlutterPlatform.instance.requestNotificationPermission();

      if (!granted) {
        debugPrint('PNTA: Notification permission denied.');
        return;
      }

      // Pure device registration with SDK version
      _deviceToken = await PntaFlutterPlatform.instance.identify(
        _config!.projectId,
      );

      // Update metadata if provided
      if (metadata != null && metadata.isNotEmpty) {
        await PntaFlutterPlatform.instance.updateMetadata(
          _config!.projectId,
          metadata,
        );
        _config!.metadata = metadata;
      }
    } catch (e, st) {
      debugPrint('PNTA: Registration error: $e\n$st');
    }
  }
}
