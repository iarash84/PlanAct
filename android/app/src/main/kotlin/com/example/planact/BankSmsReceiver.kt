package com.example.planact

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import java.security.MessageDigest

class BankSmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        messages.forEachIndexed { index, sms ->
            val body = sms.messageBody ?: return@forEachIndexed
            val receivedAt = System.currentTimeMillis()
            val key = "android-received:${sha256((sms.originatingAddress ?: "") + receivedAt + index + body)}"
            SmsBridge.publish(context, sms.originatingAddress ?: "", body, receivedAt, key)
        }
    }

    private fun sha256(value: String): String = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray())
        .joinToString("") { "%02x".format(it) }
}
