package com.iarash.planact

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

object SmsDetectionNotifications {
    private const val CHANNEL = "planact_sms_detection_generic_v2"
    private const val ID = 0x50534d
    private const val PREFS = "planact_sms_notifications_v2"
    const val EXTRA_TARGET = "planact_sms_review_target"
    const val EXTRA_BATCH = "planact_sms_review_batch"
    const val PERMISSION_REQUEST = 4107
    private var permissionResult: MethodChannel.Result? = null
    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private fun key(batch: String) = "dismissed:" + MessageDigest.getInstance("SHA-256")
        .digest(batch.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }

    @Synchronized
    fun dismiss(context: Context, batch: String) {
        require(batch.isNotBlank() && batch.length <= 256)
        check(prefs(context).edit().putBoolean(key(batch), true).commit())
    }

    fun recordTap(context: Context, intent: Intent?) {
        val batch = intent?.getStringExtra(EXTRA_BATCH) ?: return
        dismiss(context, batch)
    }

    @Synchronized
    fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        val activity = context as? MainActivity
        try {
            when (call.method) {
                "permitted" -> result.success(NotificationManagerCompat.from(context).areNotificationsEnabled())
                "requestPermission" -> {
                    if (activity == null) {
                        result.error("activity_required", "Permission UI requires an activity", null)
                    } else if (permissionResult != null) {
                        result.error("busy", "Permission request already running", null)
                    } else if (Build.VERSION.SDK_INT >= 33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                        permissionResult = result
                        activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), PERMISSION_REQUEST)
                    } else result.success(NotificationManagerCompat.from(context).areNotificationsEnabled())
                }
                "takeTap" -> {
                    val target = activity?.intent?.getStringExtra(EXTRA_TARGET)
                    recordTap(context, activity?.intent)
                    activity?.intent?.removeExtra(EXTRA_TARGET)
                    activity?.intent?.removeExtra(EXTRA_BATCH)
                    result.success(target)
                }
                "dismissed" -> {
                    val batch = requireNotNull(call.argument<String>("batchId"))
                    result.success(prefs(context).getBoolean(key(batch), false))
                }
                "dismiss" -> {
                    val batch = requireNotNull(call.argument<String>("batchId"))
                    dismiss(context, batch)
                    if (prefs(context).getString("activeBatch", null) == batch) {
                        NotificationManagerCompat.from(context).cancel(ID)
                    }
                    result.success(null)
                }
                "cancel" -> {
                    NotificationManagerCompat.from(context).cancel(ID)
                    result.success(null)
                }
                "show" -> {
                    val batch = requireNotNull(call.argument<String>("batchId"))
                    require(batch.isNotBlank() && batch.length <= 256)
                    if (prefs(context).getBoolean(key(batch), false)) {
                        result.success(false)
                        return
                    }
                    // Native copy is generated from the shared catalog. Never trust a
                    // title/body/generic/showAmounts argument with private information.
                    val title = context.getString(R.string.planact_sms_detection_title)
                    val body = context.getString(R.string.planact_sms_detection_body)
                    val manager = context.getSystemService(NotificationManager::class.java)
                    manager.createNotificationChannel(NotificationChannel(CHANNEL, title, NotificationManager.IMPORTANCE_DEFAULT).apply {
                        lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                    })
                    if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) {
                        result.error("denied", "Notification permission unavailable", null)
                        return
                    }
                    val tap = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra(EXTRA_TARGET, "pending")
                        putExtra(EXTRA_BATCH, batch)
                    }
                    val pending = PendingIntent.getActivity(context, ID, tap,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    val deletion = Intent(context, SmsNotificationDismissReceiver::class.java)
                        .setData(Uri.parse("planact-sms-dismiss://${key(batch)}"))
                        .putExtra(EXTRA_BATCH, batch)
                    val deletePending = PendingIntent.getBroadcast(context, ID, deletion,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    val silent = call.argument<Boolean>("silent") ?: true
                    val notification = NotificationCompat.Builder(context, CHANNEL)
                        .setSmallIcon(R.drawable.ic_alarm_notification)
                        .setContentTitle(title).setContentText(body)
                        .setContentIntent(pending).setDeleteIntent(deletePending).setAutoCancel(true)
                        .setOnlyAlertOnce(silent).setSilent(silent)
                        .setVisibility(NotificationCompat.VISIBILITY_PUBLIC).build()
                    check(prefs(context).edit().putString("activeBatch", batch).commit())
                    NotificationManagerCompat.from(context).notify(ID, notification)
                    result.success(true)
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

class SmsNotificationDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val batch = intent.getStringExtra(SmsDetectionNotifications.EXTRA_BATCH) ?: return
        try { SmsDetectionNotifications.dismiss(context, batch) } catch (_: Exception) {
            // No content logging. A failed durable dismissal must not cancel any
            // other batch or manufacture financial/review decisions.
        }
    }
}
