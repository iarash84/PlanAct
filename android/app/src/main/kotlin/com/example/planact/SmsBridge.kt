package com.example.planact

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

    fun attach(sink: EventChannel.EventSink) { sinks.add(sink) }
    fun detach(sink: EventChannel.EventSink) { sinks.remove(sink) }

    fun publish(context: Context, address: String, body: String, receivedAt: Long, sourceKey: String) {
        if (!hasAccess(context)) return
        val message = mapOf("sourceKey" to sourceKey, "address" to address, "body" to body, "receivedAt" to receivedAt)
        sinks.forEach { it.success(message) }
    }

    fun hasAccess(context: Context): Boolean =
        context.checkSelfPermission(Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED

    fun configureMethods(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasAccess" -> result.success(hasAccess(activity))
            "requestAccess" -> {
                if (hasAccess(activity)) result.success(true)
                else {
                    activity.requestPermissions(arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS), 4101)
                    result.success(false)
                }
            }
            "readRelevant" -> {
                if (!hasAccess(activity)) { result.success(emptyList<Map<String, Any>>()); return }
                val rows = mutableListOf<Map<String, Any>>()
                activity.contentResolver.query(
                    Telephony.Sms.Inbox.CONTENT_URI,
                    arrayOf(Telephony.Sms._ID, Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE),
                    null, null, "${Telephony.Sms.DATE} DESC"
                )?.use { cursor ->
                    val id = cursor.getColumnIndexOrThrow(Telephony.Sms._ID)
                    val address = cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
                    val body = cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)
                    val date = cursor.getColumnIndexOrThrow(Telephony.Sms.DATE)
                    while (cursor.moveToNext() && rows.size < 500) rows.add(mapOf(
                        "sourceKey" to "android-sms:${cursor.getLong(id)}",
                        "address" to (cursor.getString(address) ?: ""),
                        "body" to (cursor.getString(body) ?: ""),
                        "receivedAt" to cursor.getLong(date)
                    ))
                }
                result.success(rows)
            }
            else -> result.notImplemented()
        }
    }
}
