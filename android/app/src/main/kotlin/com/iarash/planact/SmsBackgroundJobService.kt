package com.iarash.planact

import android.app.job.JobParameters
import android.app.job.JobService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/** No parser, database SQL or consent defaults live here. Dart owns the scanner. */
class SmsBackgroundJobService : JobService() {
    private val handler = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var parameters: JobParameters? = null
    private var stopping = false
    private var wakeRevision = 0L
    private var verificationStep = 0
    private var startedAt = 0L
    private var schedulerStopped = false
    private var interrupted = false
    private val timeout = Runnable {
        // There is no safe force-close proof for Dart/SQLite. Block restore until
        // process restart rather than assert quiescence after killing an isolate.
        SmsBackgroundRuntime.poison(applicationContext)
        interrupted = true
        requestQuiescence()
        // Retain the lease/engine until complete proves database closure. The
        // process poison blocks new owners even if a late acknowledgement arrives.
        parameters?.let { if (!schedulerStopped) jobFinished(it, false) }
        schedulerStopped = true
    }

    override fun onStartJob(params: JobParameters): Boolean {
        if (!SmsBackgroundRuntime.begin(applicationContext, this)) {
            // Foreground ownership is temporary. Suspension/permission denial is not.
            if (!SmsBackgroundRuntime.blocked(this) && SmsBridge.hasAccess(this)) {
                // Finish asynchronously so JobScheduler owns the durable retry;
                // a delayed process-local callback can disappear after return false.
                handler.post { jobFinished(params, true) }
                return true
            }
            return false
        }
        parameters = params
        wakeRevision = SmsBackgroundRuntime.wakeRevision(this)
        verificationStep = SmsBackgroundRuntime.verificationStep(this)
        startedAt = System.currentTimeMillis()
        stopping = false
        schedulerStopped = false
        interrupted = false
        handler.postDelayed(timeout, 45000)
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            val flutter = FlutterEngine(applicationContext)
            engine = flutter
            val messenger = flutter.dartExecutor.binaryMessenger
            MethodChannel(messenger, "planact/sms").setMethodCallHandler { call, result ->
                SmsBridge.configureMethods(applicationContext, call, result)
            }
            MethodChannel(messenger, "planact/sms-notifications").setMethodCallHandler { call, result ->
                SmsDetectionNotifications.handle(applicationContext, call, result)
            }
            channel = MethodChannel(messenger, "planact/sms-background-worker").also { bridge ->
                bridge.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "ready" -> result.success(mapOf("budgetMillis" to 35000,
                            "maxPages" to 10, "cancelled" to stopping))
                        "isCancelled" -> result.success(stopping || SmsBackgroundRuntime.blocked(this))
                        "complete" -> {
                            // Contract: scanner/repositories must be closed before this acknowledgement.
                            val retry = call.argument<Boolean>("retry") == true || schedulerStopped
                            result.success(null)
                            handler.post { finish(retry, verified = !stopping && !interrupted) }
                        }
                        else -> result.notImplemented()
                    }
                }
            }
            flutter.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "package:planact/features/inbox/data/sms_background_entrypoint.dart",
                "smsBackgroundMain"))
        } catch (_: Exception) {
            SmsBackgroundRuntime.poison(applicationContext)
            interrupted = true
            requestQuiescence()
            // Initialization may already have started asynchronous Dart work.
            // Only its close acknowledgement or a new process can release ownership.
        }
        return true
    }

    fun requestQuiescence() {
        stopping = true
        channel?.invokeMethod("stop", null)
    }

    override fun onStopJob(params: JobParameters): Boolean {
        // Routine OS interruption is cooperative, not a durable suspension. Keep
        // ownership and the watchdog while Dart cancels and closes its database.
        if (parameters === params) {
            schedulerStopped = true
            requestQuiescence()
        }
        return true
    }

    private fun finish(retry: Boolean, verified: Boolean) {
        val params = parameters ?: return
        parameters = null
        handler.removeCallbacks(timeout)
        channel?.setMethodCallHandler(null)
        channel = null
        engine?.destroy()
        engine = null
        SmsBackgroundRuntime.ended(this)
        val prefs = getSharedPreferences("planact_sms_runtime_v1", Context.MODE_PRIVATE)
        val attempts = if (retry) prefs.getInt("attempts", 0) + 1 else 0
        val saved = prefs.edit().putInt("attempts", attempts).commit()
        if (verified) SmsBackgroundRuntime.verified(this, wakeRevision, verificationStep, startedAt)
        val again = saved && ((retry && attempts < 3) ||
            SmsBackgroundRuntime.wakeRevision(this) != wakeRevision)
        if (!schedulerStopped) jobFinished(params, false)
        // Install the persisted replacement synchronously after releasing ownership.
        // A delayed Handler callback could disappear with the process between jobs.
        // Replacement also overrides OS backoff so due verification is not swallowed.
        val delay = if (again) 30000L else SmsBackgroundRuntime.followupDelay(this)
        if (delay != null) SmsBackgroundRuntime.schedule(applicationContext, delay, replaceFinished = true)
    }

    override fun onDestroy() {
        if (parameters != null) {
            // Android may destroy the service immediately after onStopJob. This
            // does not prove SQLite closure: keep the bounded close handshake alive.
            requestQuiescence()
        }
        super.onDestroy()
    }
}

class SmsBackgroundBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            SmsBackgroundRuntime.schedule(context.applicationContext, 10000)
        }
    }
}
