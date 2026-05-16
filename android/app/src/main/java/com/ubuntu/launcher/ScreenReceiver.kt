package com.ubuntu.launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class ScreenReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_SCREEN_ON) {
            Log.d("ScreenReceiver", "Screen turned ON, launching Lomiri Lockscreen")
            val lockIntent = Intent(context, LockScreenActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            context.startActivity(lockIntent)
        }
    }
}
