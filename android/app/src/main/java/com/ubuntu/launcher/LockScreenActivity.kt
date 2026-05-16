package com.ubuntu.launcher

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class LockScreenActivity : FlutterActivity() {
    private val CHANNEL = "com.ubuntu.launcher/lockscreen"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make this activity show over the system lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        
        // Hide status bar and navigation bar
        window.setDecorFitsSystemWindows(false)
    }

    override fun getInitialRoute(): String {
        return "/lockscreen"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "unlockAndDismiss") {
                // The user successfully swiped the right edge on our custom lockscreen
                // We dismiss this activity, which reveals the underlying system UI (or Android PIN prompt)
                finish()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
