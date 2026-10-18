package com.iarash.planact

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.concurrent.Executors

class AlarmReceiver : BroadcastReceiver() {
    companion object { private val worker = Executors.newSingleThreadExecutor() }
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra("id")
        val at = intent.getLongExtra("at", -1)
        if (intent.action == "planact.alarm.FIRE" && id != null) {
            try {
                val service = Intent(context, AlarmPlaybackService::class.java).putExtra("id", id).putExtra("at", at)
                if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(service)
                else context.startService(service)
            } catch (_: Exception) { AlarmNotifications.failure(context, id) }
            return
        }
        val result = goAsync()
        worker.execute {
            try {
                val store = AlarmStore(context)
                when (intent.action) {
                    "planact.alarm.STOP" -> if (id != null) {
                        // A stale action must not stop a newer ring of the same instance.
                        AlarmPlaybackService.stopIfCurrent(context, id, at)
                    }
                    "planact.alarm.SNOOZE" -> if (id != null) {
                        if (store.snooze(id, at)) AlarmPlaybackService.remove(context, id)
                    }
                    Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED,
                    AlarmManagerAction -> store.rebuild()
                }
            } catch (_: Exception) {
                // No private payload/error text is logged. Durable intent is retained.
                if (id != null) {
                    if (intent.action == "planact.alarm.SNOOZE") AlarmPlaybackService.remove(context, id)
                    AlarmNotifications.failure(context, id)
                }
            } finally { result.finish() }
        }
    }
}

private const val AlarmManagerAction = "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED"
