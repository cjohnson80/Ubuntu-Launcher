import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemServices {
  static const MethodChannel _channel = MethodChannel('com.ubuntu.launcher/system_services');

  static Future<bool> checkOverlayPermission() async {
    final bool hasPermission = await _channel.invokeMethod('checkOverlayPermission');
    return hasPermission;
  }

  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  static Future<bool> checkUsageStatsPermission() async {
    final bool hasPermission = await _channel.invokeMethod('checkUsageStatsPermission');
    return hasPermission;
  }

  static Future<void> requestUsageStatsPermission() async {
    await _channel.invokeMethod('requestUsageStatsPermission');
  }

  static Future<bool> checkNotificationPermission() async {
    final bool hasPermission = await _channel.invokeMethod('checkNotificationPermission');
    return hasPermission;
  }

  static Future<void> requestNotificationPermission() async {
    await _channel.invokeMethod('requestNotificationPermission');
  }

  static Future<bool> launchLastUsedApp() async {
    try {
      final bool result = await _channel.invokeMethod('launchLastUsedApp');
      return result;
    } on PlatformException catch (e) {
      print("Failed to launch last used app: '${e.message}'.");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getBatteryLevel() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getBatteryLevel');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException catch (e) {
      print("Failed to get battery level: '${e.message}'.");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getVolume() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getVolume');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException catch (e) {
      print("Failed to get volume: '${e.message}'.");
      return null;
    }
  }

  static Future<bool> setVolume(int volume) async {
    try {
      final bool result = await _channel.invokeMethod('setVolume', {'volume': volume});
      return result;
    } on PlatformException catch (e) {
      print("Failed to set volume: '${e.message}'.");
      return false;
    }
  }

  static Future<void> openWifiSettings() async {
    try {
      await _channel.invokeMethod('openWifiSettings');
    } on PlatformException catch (e) {
      print("Failed to open wifi settings: '${e.message}'.");
    }
  }

  static Future<void> openBluetoothSettings() async {
    try {
      await _channel.invokeMethod('openBluetoothSettings');
    } on PlatformException catch (e) {
      print("Failed to open bluetooth settings: '${e.message}'.");
    }
  }

  static Future<void> closeSystemPanels() async {
    try {
      await _channel.invokeMethod('closeSystemPanels');
    } on PlatformException catch (e) {
      print("Failed to close system panels: '${e.message}'.");
    }
  }

  static Future<void> closeApp(String packageName) async {
    try {
      await _channel.invokeMethod('closeApp', {'packageName': packageName});
    } on PlatformException catch (e) {
      print("Failed to close app $packageName: '${e.message}'.");
    }
  }

  static Future<void> setAsDefaultLauncher() async {
    try {
      await _channel.invokeMethod('setAsDefaultLauncher');
    } on PlatformException catch (e) {
      print("Failed to set as default launcher: '${e.message}'.");
    }
  }

  static Future<bool> showRecentApps() async {
    try {
      final bool result = await _channel.invokeMethod('showRecentApps');
      return result;
    } on PlatformException catch (e) {
      print("Failed to show recent apps: '${e.message}'.");
      return false;
    }
  }

  static Future<List<String>> getRecentApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getRecentApps');
      return result.cast<String>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> startEdgeOverlayService() async {
    final prefs = await SharedPreferences.getInstance();
    double width = prefs.getDouble('edge_sensitivity') ?? 30.0;
    await _channel.invokeMethod('startEdgeOverlayService', {'width': width.toInt()});
  }

  static Function(List<String>)? _onAppsUpdated;

  static void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'updateRunningApps') {
        final List<String> apps = List<String>.from(call.arguments);
        if (_onAppsUpdated != null) _onAppsUpdated!(apps);
      }
      if (handler != null) return handler(call);
    });
  }

  static void setOnAppsUpdated(Function(List<String>) callback) {
    _onAppsUpdated = callback;
  }

  static Future<void> updateEdgeSensitivity(double width) async {
    await _channel.invokeMethod('updateEdgeSensitivity', {'width': width.toInt()});
  }
}
