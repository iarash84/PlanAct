package com.iarash.planact

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object SmsDetectionNotifications {
    private const val CHANNEL = "planact_sms_detection_v1"
    private const val ID = 0x50534d
    const val EXTRA_TARGET = "planact_sms_review_target"
    const val PERMISSION_REQUEST = 4107
    private var permissionResult: MethodChannel.Result? = null

    fun handle(activity: MainActivity, call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "permitted" -> result.success(NotificationManagerCompat.from(activity).areNotificationsEnabled())
                "requestPermission" -> {
                    if (permissionResult != null) {
                        result.error("busy", "Permission request already running", null)
                    } else if (Build.VERSION.SDK_INT >= 33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                        permissionResult = result
                        activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), PERMISSION_REQUEST)
                    } else result.success(NotificationManagerCompat.from(activity).areNotificationsEnabled())
                }
                "takeTap" -> {
                    val target = activity.intent?.getStringExtra(EXTRA_TARGET)
                    activity.intent?.removeExtra(EXTRA_TARGET)
                    result.success(target)
                }
                "cancel" -> {
                    NotificationManagerCompat.from(activity).cancel(ID)
                    result.success(null)
                }
                "show" -> {
                    val title = call.argument<String>("title") ?: error("Missing title")
                    val body = call.argument<String>("body") ?: error("Missing body")
                    val generic = call.argument<String>("generic") ?: error("Missing generic copy")
                    val target = call.argument<String>("target") ?: "pending"
                    val manager = activity.getSystemService(NotificationManager::class.java)
                    manager.createNotificationChannel(NotificationChannel(CHANNEL, title, NotificationManager.IMPORTANCE_DEFAULT).apply {
                        lockscreenVisibility = Notification.VISIBILITY_PRIVATE
                    })
                    if (!NotificationManagerCompat.from(activity).areNotificationsEnabled()) {
                        result.error("denied", "Notification permission unavailable", null)
                        return
                    }
                    val tap = Intent(activity, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra(EXTRA_TARGET, target)
                    }
                    val pending = PendingIntent.getActivity(activity, ID, tap, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    val public = NotificationCompat.Builder(activity, CHANNEL)
                        .setSmallIcon(R.drawable.ic_alarm_notification)
                        .setContentTitle(title).setContentText(generic)
                        .setVisibility(NotificationCompat.VISIBILITY_PUBLIC).build()
                    val notification = NotificationCompat.Builder(activity, CHANNEL)
                        .setSmallIcon(R.drawable.ic_alarm_notification)
                        .setContentTitle(title).setContentText(body)
                        .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                        .setContentIntent(pending).setAutoCancel(true).setOnlyAlertOnce(true)
                        .setVisibility(NotificationCompat.VISIBILITY_PRIVATE).setPublicVersion(public).build()
                    NotificationManagerCompat.from(activity).notify(ID, notification)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (_: Exception) {
            result.error("sms_notification_failed", "SMS notification operation failed", null)
        }
    }

    fun permissionFinished(activity: MainActivity) {
        permissionResult?.success(NotificationManagerCompat.from(activity).areNotificationsEnabled())
        permissionResult = null
    }

    fun detach() {
        permissionResult?.error("activity_closed", "Activity closed", null)
        permissionResult = null
    }
}
