package com.iarash.planact

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build

internal object AlarmNotifications {
    const val channelId = "planact_alarm_v1"
    const val foregroundId = -48271 // Ordinary reminder IDs are nonnegative.
    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)

    fun channel(context: Context) {
        if (Build.VERSION.SDK_INT >= 26) {
            manager(context).createNotificationChannel(NotificationChannel(channelId,
                context.getString(R.string.planact_alarm_channel), NotificationManager.IMPORTANCE_HIGH).apply {
                description = context.getString(R.string.planact_alarm_channel_description)
                // A bounded USAGE_ALARM player owns sound, not the notification.
                setSound(null, null)
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            })
        }
    }

    fun enabled(context: Context): Boolean = manager(context).areNotificationsEnabled() &&
        (Build.VERSION.SDK_INT < 26 || manager(context).getNotificationChannel(channelId)?.importance != NotificationManager.IMPORTANCE_NONE)

    private fun action(context: Context, id: String, at: Long, action: String): PendingIntent =
        PendingIntent.getBroadcast(context, 0,
            Intent(context, AlarmReceiver::class.java).setAction(action)
                .setData(Uri.parse("planact-alarm://action/$id/$at/$action"))
                .putExtra("id", id).putExtra("at", at), PendingIntent.FLAG_IMMUTABLE)

    fun build(context: Context, id: String, at: Long): Notification {
        channel(context)
        val open = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channelId)
            else Notification.Builder(context)
        return builder.setSmallIcon(R.drawable.ic_alarm_notification)
            .setContentTitle(context.getString(R.string.planact_alarm_title))
            .setContentText(context.getString(R.string.planact_alarm_body))
            .setContentIntent(open).setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PRIVATE).setOngoing(true)
            .setPriority(Notification.PRIORITY_MAX).setOnlyAlertOnce(true)
            .addAction(Notification.Action.Builder(null, context.getString(R.string.planact_alarm_stop),
                action(context, id, at, "planact.alarm.STOP")).build())
            .addAction(Notification.Action.Builder(null, context.getString(R.string.planact_alarm_snooze),
                action(context, id, at, "planact.alarm.SNOOZE")).build())
            .build()
    }

    fun failure(context: Context, id: String) {
        if (!enabled(context)) return
        channel(context)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channelId)
            else Notification.Builder(context)
        manager(context).notify("alarm-error:$id", 0, builder
            .setSmallIcon(R.drawable.ic_alarm_notification)
            .setContentTitle(context.getString(R.string.planact_alarm_title))
            .setContentText(context.getString(R.string.planact_alarm_retry))
            .setVisibility(Notification.VISIBILITY_PRIVATE).setAutoCancel(true).build())
    }

    fun cancel(context: Context, id: String) { manager(context).cancel(id, 0) }
}
