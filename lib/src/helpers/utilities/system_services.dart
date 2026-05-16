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

  static void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    _channel.setMethodCallHandler(handler);
  }

  static Future<void> updateEdgeSensitivity(double width) async {
    await _channel.invokeMethod('updateEdgeSensitivity', {'width': width.toInt()});
  }
}
