package com.ubuntu.launcher

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ubuntu.launcher/system_services"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(true)
                }
                "checkUsageStatsPermission" -> {
                    val appOps = getSystemService(android.content.Context.APP_OPS_SERVICE) as android.app.AppOpsManager
                    val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        appOps.unsafeCheckOpNoThrow(
                            android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                            android.os.Process.myUid(), packageName
                        )
                    } else {
                        appOps.checkOpNoThrow(
                            android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                            android.os.Process.myUid(), packageName
                        )
                    }
                    result.success(mode == android.app.AppOpsManager.MODE_ALLOWED)
                }
                "requestUsageStatsPermission" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "checkNotificationPermission" -> {
                    // Check if we have notification listener permission
                    val listeners = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                    result.success(listeners != null && listeners.contains(packageName))
                }
                "requestNotificationPermission" -> {
                    val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                    startActivity(intent)
                    result.success(true)
                }
                "startEdgeOverlayService" -> {
                    val width = call.argument<Int>("width") ?: 30
                    val intent = Intent(this, EdgeOverlayService::class.java).apply {
                        putExtra("action", "update_width")
                        putExtra("width", width)
                    }
                    startService(intent)
                    result.success(true)
                }
                "updateEdgeSensitivity" -> {
                    val width = call.argument<Int>("width") ?: 30
                    val intent = Intent(this, EdgeOverlayService::class.java).apply {
                        putExtra("action", "update_width")
                        putExtra("width", width)
                    }
                    startService(intent)
                    result.success(true)
                }
                "getRecentApps" -> {
                    result.success(getRecentAppsList())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getRecentAppsList(): List<String> {
        val usageStatsManager = getSystemService(android.content.Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -1) // Look back 1 day

        val events = usageStatsManager.queryEvents(cal.timeInMillis, System.currentTimeMillis())
        val event = UsageEvents.Event()
        
        // We want to keep the most recent apps ordered by last used time
        // A LinkedHashMap keeps insertion order, but we want to update the position 
        // when an app is seen again.
        val recentPackages = mutableListOf<String>()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            // Look for apps moving to the foreground
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                val pkg = event.packageName
                if (pkg != packageName && pkg != "com.google.android.apps.nexuslauncher") {
                    recentPackages.remove(pkg) // Remove if exists to push to front
                    recentPackages.add(0, pkg) // Add to front of list (most recent)
                }
            }
        }
        
        // Return top 15 recent apps
        return recentPackages.take(15)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.getStringExtra("action") == "open_dock") {
            methodChannel?.invokeMethod("openDock", null)
            intent.removeExtra("action") // consume it
        }
    }
}
