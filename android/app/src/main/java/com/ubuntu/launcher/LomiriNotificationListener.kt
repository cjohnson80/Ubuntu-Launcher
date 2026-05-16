package com.ubuntu.launcher

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class LomiriNotificationListener : NotificationListenerService() {
    private val TAG = "LomiriNotificationListener"

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        sbn?.let {
            Log.d(TAG, "Notification Posted: ${it.packageName} - ${it.notification.tickerText}")
            // TODO: Route to Flutter via EventChannel
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        sbn?.let {
            Log.d(TAG, "Notification Removed: ${it.packageName}")
            // TODO: Notify Flutter
        }
    }
}
