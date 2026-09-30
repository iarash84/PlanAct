package com.iarash.planact

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.provider.Telephony
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CopyOnWriteArrayList

object SmsBridge {
    private val sinks = CopyOnWriteArrayList<EventChannel.EventSink>()
    private const val permissionRequestCode = 4101
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
                if (hasAccess(activity)) result.success(true)
                else {
                    activity.requestPermissions(arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS), permissionRequestCode)
                    result.success(false)
                }
            }
            "readRelevant" -> {
                if (!hasAccess(activity)) { result.success(emptyList<Map<String, Any>>()); return }
                val rows = mutableListOf<Map<String, Any>>()
                activity.contentResolver.query(
                    Telephony.Sms.Inbox.CONTENT_URI,
                    arrayOf(Telephony.Sms._ID, Telephony.Sms.BODY, Telephony.Sms.DATE),
                    null, null, "${Telephony.Sms.DATE} DESC"
                )?.use { cursor ->
                    val id = cursor.getColumnIndexOrThrow(Telephony.Sms._ID)
                    val body = cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)
                    val date = cursor.getColumnIndexOrThrow(Telephony.Sms.DATE)
                    val seen = mutableSetOf<String>()
                    while (cursor.moveToNext() && rows.size < 500) {
                        val text = cursor.getString(body)?.trim().orEmpty()
                        val key = "android-sms:${cursor.getLong(id)}"
                        if (isRelevant(text) && seen.add(key)) rows.add(mapOf(
                            "sourceKey" to key, "body" to text, "receivedAt" to cursor.getLong(date)
                        ))
                    }
                }
                result.success(rows)
            }
            else -> result.notImplemented()
        }
    }
}
