package com.iarash.planact

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.provider.Telephony
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors

object SmsBridge {
    private val sinks = CopyOnWriteArrayList<EventChannel.EventSink>()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val reader = Executors.newSingleThreadExecutor()
    private const val permissionRequestCode = 4101
    private const val permissionRequestedPreference = "sms_permission_requested"
    private val relevantMarkers = Regex(
        "(?i)(برداشت|واریز|انتقال|مبلغ|موجودی|کارت|بانک|\b(?:atm|pos|iban|شبا|رمز)\b|[۰-۹]{3,})"
    )

    fun attach(sink: EventChannel.EventSink) { sinks.add(sink) }
    fun detach(sink: EventChannel.EventSink) { sinks.remove(sink) }

    fun publish(context: Context, address: String, body: String, receivedAt: Long, sourceKey: String) {
        if (!hasAccess(context)) return
        val normalized = body.trim()
        if (!isRelevant(normalized)) return
        // Do not forward or log the raw sender number. The staged body is still
        // subject to Dart retention and explicit financial confirmation.
        val message = mapOf("sourceKey" to sourceKey, "body" to normalized, "receivedAt" to receivedAt)
        sinks.forEach { it.success(message) }
    }

    internal fun isRelevant(body: String): Boolean = body.trim().isNotEmpty() && relevantMarkers.containsMatchIn(body)

    fun hasAccess(context: Context): Boolean =
        context.checkSelfPermission(Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED &&
            context.checkSelfPermission(Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED

    fun configureMethods(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasAccess" -> result.success(hasAccess(activity))
            "requestAccess" -> {
                if (hasAccess(activity)) {
                    result.success(true)
                } else if (activity.isFinishing || activity.isDestroyed) {
                    result.error("activity_unavailable", "The activity is not available", null)
                } else {
                    val preferences = activity.getPreferences(Context.MODE_PRIVATE)
                    val wasRequested = preferences.getBoolean(permissionRequestedPreference, false)
                    val permanentlyDenied = wasRequested &&
                        !activity.shouldShowRequestPermissionRationale(Manifest.permission.READ_SMS) &&
                        !activity.shouldShowRequestPermissionRationale(Manifest.permission.RECEIVE_SMS)
                    if (permanentlyDenied) {
                        openApplicationSettings(activity)
                        result.success(false)
                    } else {
                        preferences.edit().putBoolean(permissionRequestedPreference, true).apply()
                        // Keep the permission dialog in the activity's UI queue. This
                        // avoids racing Flutter's just-dismissed AlertDialog and
                        // guarantees requestPermissions runs on the main thread.
                        mainHandler.post {
                            if (activity.isFinishing || activity.isDestroyed) return@post
                            try {
                                activity.requestPermissions(
                                    arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
                                    permissionRequestCode
                                )
                            } catch (_: Exception) {
                                // The Dart side will report the unavailable request
                                // after its bounded access poll completes.
                            }
                        }
                        // Do not keep a MethodChannel result pending while Android
                        // owns the permission dialog. Some OEMs do not deliver the
                        // legacy callback back to FlutterActivity.
                        result.success(true)
                    }
                }
            }
            "readPage" -> {
                val from = call.argument<Number>("from")?.toLong()
                val until = call.argument<Number>("until")?.toLong()
                val afterDate = call.argument<Number>("afterTimestamp")?.toLong()
                val afterId = call.argument<Number>("afterId")?.toLong()
                val limit = call.argument<Number>("limit")?.toInt()
                if (from == null || until == null || afterDate == null || afterId == null ||
                    from < 0 || until < from || limit != 100) {
                    result.error("invalid_sms_bounds", "Explicit SMS bounds are required", null)
                    return
                }
                val context = activity.applicationContext
                reader.execute {
                    try {
                        if (!hasAccess(context)) throw SecurityException()
                        val rows = mutableListOf<Map<String, Any>>()
                        val dateColumn = Telephony.Sms.DATE
                        val idColumn = Telephony.Sms._ID
                        val selection = "$dateColumn >= ? AND $dateColumn <= ? AND " +
                            "($dateColumn > ? OR ($dateColumn = ? AND $idColumn > ?))"
                        context.contentResolver.query(
                            Telephony.Sms.Inbox.CONTENT_URI,
                            arrayOf(idColumn, Telephony.Sms.BODY, dateColumn), selection,
                            arrayOf(from.toString(), until.toString(), afterDate.toString(),
                                afterDate.toString(), afterId.toString()),
                            "$dateColumn ASC, $idColumn ASC LIMIT 100"
                        )?.use { cursor ->
                            val id = cursor.getColumnIndexOrThrow(idColumn)
                            val body = cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)
                            val date = cursor.getColumnIndexOrThrow(dateColumn)
                            while (rows.size < 100 && cursor.moveToNext()) {
                                val rowId = cursor.getLong(id)
                                val timestamp = cursor.getLong(date)
                                val text = cursor.getString(body)?.trim().orEmpty()
                                val row = mutableMapOf<String, Any>("id" to rowId,
                                    "receivedAt" to timestamp)
                                if (isRelevant(text)) {
                                    row["sourceKey"] = "android-sms:$rowId"
                                    row["body"] = text
                                }
                                rows.add(row)
                            }
                        } ?: throw IllegalStateException("Provider unavailable")
                        mainHandler.post { result.success(rows) }
                    } catch (_: SecurityException) {
                        mainHandler.post { result.error("sms_access_revoked", "SMS access is unavailable", null) }
                    } catch (_: Exception) {
                        mainHandler.post { result.error("sms_read_failed", "SMS import failed", null) }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun openApplicationSettings(activity: Activity) {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${activity.packageName}")
        )
        activity.startActivity(intent)
    }

    fun onRequestPermissionsResult(activity: Activity, requestCode: Int): Boolean {
        return requestCode == permissionRequestCode
    }
}
