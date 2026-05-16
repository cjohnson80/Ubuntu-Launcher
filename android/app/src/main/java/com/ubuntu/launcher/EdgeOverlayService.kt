package com.ubuntu.launcher

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.util.Log

class EdgeOverlayService : Service() {
    private val TAG = "EdgeOverlayService"
    private var windowManager: WindowManager? = null
    private var leftEdgeView: View? = null
    private var currentWidth = 30 // Default width
    private var screenReceiver: ScreenReceiver? = null

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.getStringExtra("action") == "update_width") {
            val newWidth = intent.getIntExtra("width", 30)
            if (newWidth != currentWidth) {
                currentWidth = newWidth
                updateOverlayWidth()
            }
        }
        return START_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Edge Overlay Service Created")
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createLeftEdgeOverlay()

        // Register ScreenReceiver for Lomiri Lockscreen
        screenReceiver = ScreenReceiver()
        val filter = IntentFilter(Intent.ACTION_SCREEN_ON)
        registerReceiver(screenReceiver, filter)
    }

    private fun createLeftEdgeOverlay() {
        leftEdgeView = View(this)
        // Invisible touch target
        leftEdgeView?.setBackgroundColor(Color.TRANSPARENT)

        val params = WindowManager.LayoutParams(
            currentWidth, // dynamic width
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.LEFT or Gravity.TOP

        leftEdgeView?.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0f
            private val swipeThreshold = 50f // pixels to swipe to trigger

            override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                if (event == null) return false
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = event.rawX
                        return true
                    }
                    MotionEvent.ACTION_UP, MotionEvent.ACTION_MOVE -> {
                        val currentX = event.rawX
                        val deltaX = currentX - initialX
                        if (deltaX > swipeThreshold) {
                            Log.d(TAG, "Left Edge Swipe Detected!")
                            launchLauncher()
                            // Reset to avoid multiple triggers on one swipe
                            initialX = currentX 
                        }
                        return true
                    }
                }
                return false
            }
        })

        windowManager?.addView(leftEdgeView, params)
    }

    private fun updateOverlayWidth() {
        leftEdgeView?.let { view ->
            val params = view.layoutParams as WindowManager.LayoutParams
            params.width = currentWidth
            windowManager?.updateViewLayout(view, params)
            Log.d(TAG, "Overlay width updated to: $currentWidth")
        }
    }

    private fun launchLauncher() {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            // We can pass an extra to tell Flutter to immediately open the dock
            putExtra("action", "open_dock")
            putExtra("sidebar_only", true)
        }
        startActivity(launchIntent)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (leftEdgeView != null) {
            windowManager?.removeView(leftEdgeView)
        }
        screenReceiver?.let {
            unregisterReceiver(it)
        }
        Log.d(TAG, "Edge Overlay Service Destroyed")
    }
}
