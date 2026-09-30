package com.iarash.planact

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import java.security.MessageDigest

class BankSmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isEmpty()) return
        // The Android API can deliver one multipart SMS as several PDUs. Join it
        // once, filter before crossing the Flutter boundary, and never log raw
        // content or sender identifiers.
        val body = messages.joinToString(separator = "") { it.messageBody.orEmpty() }.trim()
        if (body.isEmpty()) return
        val receivedAt = System.currentTimeMillis()
        val key = "android-received:${sha256(receivedAt.toString() + body)}"
        SmsBridge.publish(context, "", body, receivedAt, key)
    }

    private fun sha256(value: String): String = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray())
        .joinToString("") { "%02x".format(it) }
}
