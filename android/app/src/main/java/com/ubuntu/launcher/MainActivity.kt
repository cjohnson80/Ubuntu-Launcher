package com.ubuntu.launcher

import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import android.app.StatusBarManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ubuntu.launcher/system_services"
    private var methodChannel: MethodChannel? = null
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private var lastForegroundApp: String? = null
    
    private val screenReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: android.content.Context?, intent: android.content.Intent?) {
            if (intent?.action == android.content.Intent.ACTION_SCREEN_OFF) {
                val lockIntent = android.content.Intent(context, LockScreenActivity::class.java).apply {
                    addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                }
                context?.startActivity(lockIntent)
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Register Screen Off Receiver
        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        registerReceiver(screenReceiver, filter)
        
        // Start Periodic App Polling for Dock
        startAppPolling()
        
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
                "launchLastUsedApp" -> {
                    val recentApps = getRecentAppsList()
                    if (recentApps.isNotEmpty()) {
                        val lastUsedPkg = recentApps[0]
                        val launchIntent = packageManager.getLaunchIntentForPackage(lastUsedPkg)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                            startActivity(launchIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "getBatteryLevel" -> {
                    val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                    val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                    val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
                    val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
                    val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
                    
                    if (level == -1 || scale == -1) {
                        result.error("UNAVAILABLE", "Battery level not available.", null)
                    } else {
                        val batteryPct = level * 100 / scale.toFloat()
                        result.success(mapOf("level" to batteryPct.toInt(), "isCharging" to isCharging))
                    }
                }
                "getVolume" -> {
                    val audioManager = getSystemService(android.content.Context.AUDIO_SERVICE) as AudioManager
                    val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                    val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    result.success(mapOf("current" to currentVolume, "max" to maxVolume))
                }
                "setVolume" -> {
                    val volume = call.argument<Int>("volume") ?: 0
                    val audioManager = getSystemService(android.content.Context.AUDIO_SERVICE) as AudioManager
                    audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume, 0)
                    result.success(true)
                }
                "openWifiSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        startActivity(Intent(Settings.Panel.ACTION_WIFI))
                    } else {
                        startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                    }
                    result.success(true)
                }
                "openBluetoothSettings" -> {
                    startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                    result.success(true)
                }
                "closeSystemPanels" -> {
                    try {
                        val statusBarService = getSystemService("statusbar")
                        val statusBarClass = Class.forName("android.app.StatusBarManager")
                        val method = statusBarClass.getMethod("collapsePanels")
                        method.invoke(statusBarService)
                        result.success(true)
                    } catch (e: Exception) {
                        // Fallback for newer Android versions or restricted access
                        val it = Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS)
                        sendBroadcast(it)
                        result.success(true)
                    }
                }
                "closeApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val activityManager = getSystemService(android.content.Context.ACTIVITY_SERVICE) as android.app.ActivityManager
                        activityManager.killBackgroundProcesses(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is null", null)
                    }
                }
                "setAsDefaultLauncher" -> {
                    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        Intent(Settings.ACTION_HOME_SETTINGS)
                    } else {
                        Intent(Settings.ACTION_SETTINGS)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "showRecentApps" -> {
                    try {
                        val intent = Intent("com.android.systemui.recents.SHOW_RECENTS")
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // Fallback: Accessibility service or other methods are often needed for this
                        // but we'll try a generic intent first.
                        result.success(false)
                    }
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
                    // Filter: Only show apps that have a launch intent (user apps/launchable services)
                    val intent = packageManager.getLaunchIntentForPackage(pkg)
                    if (intent != null) {
                        recentPackages.remove(pkg) // Remove if exists to push to front
                        recentPackages.add(0, pkg) // Add to front of list (most recent)
                    }
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
            val isSidebarOnly = intent.getBooleanExtra("sidebar_only", false)
            methodChannel?.invokeMethod("openDock", mapOf("sidebarOnly" to isSidebarOnly))
            intent.removeExtra("action") // consume it
            intent.removeExtra("sidebar_only")
        }
    }

    private fun startAppPolling() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                val apps = getRecentAppsList()
                val currentTop = if (apps.isNotEmpty()) apps[0] else null
                
                if (currentTop != lastForegroundApp) {
                    lastForegroundApp = currentTop
                    methodChannel?.invokeMethod("updateRunningApps", apps)
                }
                
                handler.postDelayed(this, 1500) // Poll every 1.5s
            }
        }, 1500)
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(screenReceiver)
        handler.removeCallbacksAndMessages(null)
    }
}
