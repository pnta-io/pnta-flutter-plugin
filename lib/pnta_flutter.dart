import 'package:flutter/material.dart';
import 'src/link_handler.dart';
import 'src/version.dart';
import 'pnta_flutter_platform_interface.dart';

class PntaFlutterConfig {
  final String projectId;
  final bool autoHandleLinks;
  final bool showSystemUI;
  final bool requestPermission;
  final Map<String, dynamic>? metadata;

  PntaFlutterConfig({
    required this.projectId,
    required this.autoHandleLinks,
    required this.showSystemUI,
    required this.requestPermission,
    this.metadata,
  });
}

class PntaFlutter {
  static PntaFlutterConfig? _config;
  static bool _isInitialized = false;
  static bool _isInitializing = false;
  static String? _deviceToken;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Main initialization - handles everything for most apps
  static Future<String?> initialize(
    String projectId, {
    Map<String, dynamic>? metadata,
    bool requestPermission = true,
    bool autoHandleLinks = true,
    bool showSystemUI = false,
  }) async {
    if (_isInitializing) {
      debugPrint('PNTA: Initialization already in progress.');
      return null;
    }
    if (_isInitialized) {
      debugPrint('PNTA: Already initialized.');
      return _deviceToken;
    }
    _isInitializing = true;
    try {
      // Validate project ID
      if (!projectId.startsWith('prj_')) {
        debugPrint('PNTA: Invalid project ID. Must start with "prj_".');
        _isInitializing = false;
        return null;
      }
      _config = PntaFlutterConfig(
        projectId: projectId,
        autoHandleLinks: autoHandleLinks,
        showSystemUI: showSystemUI,
        requestPermission: requestPermission,
        metadata: metadata,
      );
      LinkHandler.initialize(autoHandleLinks: autoHandleLinks);
      await PntaFlutterPlatform.instance.setForegroundPresentationOptions(showSystemUI: showSystemUI);
      if (requestPermission) {
        final granted = await PntaFlutterPlatform.instance.requestNotificationPermission();
        if (!granted) {
          debugPrint('PNTA: Notification permission denied.');
          _isInitializing = false;
          _isInitialized = true;
          return null;
        }
        _deviceToken = await PntaFlutterPlatform.instance.identify(
          projectId,
          metadata: {
            ...?metadata,
            'pntaSdkVersion': kPntaSdkVersion,
          },
        );
        _isInitialized = true;
        _isInitializing = false;
        return _deviceToken;
      } else {
        // Delayed permission scenario
        _isInitialized = true;
        _isInitializing = false;
        return null;
      }
    } catch (e, st) {
      debugPrint('PNTA: Initialization error: $e\n$st');
      _isInitializing = false;
      return null;
    }
  }

  /// For delayed permission scenarios: requests permission, gets token, and registers device
  static Future<String?> requestPermissionAndRegister({Map<String, dynamic>? metadata}) async {
    if (_config == null) {
      debugPrint('PNTA: Must call initialize() before requesting permission.');
      return null;
    }
    try {
      final granted = await PntaFlutterPlatform.instance.requestNotificationPermission();
      if (!granted) {
        debugPrint('PNTA: Notification permission denied.');
        return null;
      }
      _deviceToken = await PntaFlutterPlatform.instance.identify(
        _config!.projectId,
        metadata: {
          ...?_config!.metadata,
          ...?metadata,
          'pntaSdkVersion': kPntaSdkVersion,
        },
      );
      return _deviceToken;
    } catch (e, st) {
      debugPrint('PNTA: requestPermissionAndRegister error: $e\n$st');
      return null;
    }
  }

  /// Non-critical metadata updates
  static Future<void> updateMetadata(Map<String, dynamic> metadata) async {
    if (_config == null) {
      debugPrint('PNTA: Must call initialize() before updating metadata.');
      return;
    }
    try {
      await PntaFlutterPlatform.instance.updateMetadata(_config!.projectId, metadata);
    } catch (e, st) {
      debugPrint('PNTA: updateMetadata error: $e\n$st');
    }
  }

  /// Notification streams
  static Stream<Map<String, dynamic>> get foregroundNotifications =>
      PntaFlutterPlatform.instance.foregroundNotifications;

  static Stream<Map<String, dynamic>> get onNotificationTap =>
      PntaFlutterPlatform.instance.onNotificationTap.asyncMap((payload) async {
        if (_config?.autoHandleLinks == true) {
          await handleLink(payload['link_to'] as String?);
        }
        return payload;
      });

  /// Manual link handling
  static Future<bool> handleLink(String? link) async {
    return await LinkHandler.handleLink(link);
  }

  /// Configuration access
  static String? get projectId => _config?.projectId;
  static bool get isInitialized => _isInitialized;
  static bool get autoHandleLinks => _config?.autoHandleLinks ?? false;
  static bool get showSystemUI => _config?.showSystemUI ?? false;
  static Map<String, dynamic>? get currentMetadata => _config?.metadata;
  static String? get deviceToken => _deviceToken;
}
