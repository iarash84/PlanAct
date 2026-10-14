package com.iarash.planact

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

internal object AlarmBridge {
    private val worker = Executors.newSingleThreadExecutor()
    fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        worker.execute {
            try {
                val store = AlarmStore(context)
                val value: Any? = when (call.method) {
                    "configure" -> { store.configure(call.argument<String>("path")!!, call.argument<Int>("schema")!!); null }
                    "available" -> store.available()
                    "schedule" -> store.schedule(call.argument<String>("id")!!, call.argument<Number>("at")!!.toLong())
                    "cancel" -> { store.cancelIfObsolete(call.argument<String>("id")!!); null }
                    "removeOrphans" -> { store.removeObsolete(call.argument<List<String>>("active")!!.toSet()); null }
                    "suspend" -> { store.suspendAlarms(); null }
                    else -> throw IllegalArgumentException("Unsupported alarm operation")
                }
                Handler(Looper.getMainLooper()).post { result.success(value) }
            } catch (_: Exception) {
                // Do not expose database paths or personal values through bridge errors.
                Handler(Looper.getMainLooper()).post { result.error("alarm_unavailable", "Alarm operation unavailable", null) }
            }
        }
    }
}
