package com.iarash.planact

import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** One process, one scanner. Persisted suspension survives process death/reboot. */
internal object SmsBackgroundRuntime {
    const val CHANNEL = "planact/sms-background"
    const val JOB_ID = 0x50534e
    private const val PREFS = "planact_sms_runtime_v1"
    private var foregroundOwner: BinaryMessenger? = null
    var running: SmsBackgroundJobService? = null
        private set
    private var poisoned = false
    private var recoveredInterruption = false
    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    fun blocked(context: Context): Boolean {
        val p = prefs(context)
        val path = p.getString("path", null)
        if (!recoveredInterruption) {
            // Only a new process can prove the interrupted isolate no longer exists.
            // Legacy/restore/manual pauses and a restore marker always fail closed.
            if (!poisoned && p.getString("pauseReason", null) == "interrupted" &&
                path != null && !File("$path.restore-marker").exists()) {
                check(p.edit().putBoolean("paused", false).remove("pauseReason").commit())
            }
            recoveredInterruption = true
        }
        return poisoned || p.getBoolean("paused", false) || path == null ||
            File("$path.restore-marker").exists()
    }

    @Synchronized
    fun wake(context: Context): Boolean {
        if (!SmsBridge.hasAccess(context)) return false
        val p = prefs(context)
        check(p.edit().putLong("wakeRevision", p.getLong("wakeRevision", 0) + 1)
            .putLong("verificationOrigin", System.currentTimeMillis())
            .putInt("verificationStep", 0).putInt("attempts", 0).commit())
        return schedule(context)
    }

    @Synchronized
    fun wakeRevision(context: Context): Long = prefs(context).getLong("wakeRevision", 0)

    private val verificationOffsets = longArrayOf(2000, 8000, 30000)

    @Synchronized
    fun verificationStep(context: Context): Int = prefs(context).getInt("verificationStep", 0)

    @Synchronized
    fun verified(context: Context, revision: Long, step: Int, startedAt: Long) {
        val p = prefs(context)
        if (p.getLong("wakeRevision", 0) != revision || p.getInt("verificationStep", 0) != step) return
        val origin = p.getLong("verificationOrigin", 0)
        var next = step
        // Only consume checkpoints already due when this scan STARTED. A long scan
        // is not proof that the provider was checked again at its completion time.
        while (origin > 0 && next < verificationOffsets.size &&
            startedAt >= origin + verificationOffsets[next]) next++
        check(p.edit().putInt("verificationStep", next).commit())
    }

    @Synchronized
    fun followupDelay(context: Context): Long? {
        val p = prefs(context)
        val origin = p.getLong("verificationOrigin", 0)
        val step = p.getInt("verificationStep", 0)
        if (origin <= 0 || step !in verificationOffsets.indices) return null
        return (origin + verificationOffsets[step] - System.currentTimeMillis()).coerceAtLeast(0)
    }

    @Synchronized
    fun schedule(context: Context, delayMillis: Long = 1500, replaceFinished: Boolean = false): Boolean {
        if (blocked(context) || !SmsBridge.hasAccess(context)) return false
        val scheduler = context.getSystemService(JobScheduler::class.java)
        // Coalesce broadcasts without replacing a running job or moving its deadline.
        if (running != null || (!replaceFinished && scheduler.getPendingJob(JOB_ID) != null)) return true
        val delay = minOf(delayMillis, followupDelay(context) ?: delayMillis)
        return scheduler.schedule(JobInfo.Builder(JOB_ID,
            ComponentName(context, SmsBackgroundJobService::class.java))
            .setMinimumLatency(delay).setOverrideDeadline(delay + 15000)
            .setBackoffCriteria(30000, JobInfo.BACKOFF_POLICY_EXPONENTIAL)
            .setPersisted(true).build()) == JobScheduler.RESULT_SUCCESS
    }

    @Synchronized
    fun begin(context: Context, service: SmsBackgroundJobService): Boolean {
        if (blocked(context) || running != null || foregroundOwner != null || !SmsBridge.hasAccess(context)) return false
        running = service
        return true
    }

    @Synchronized
    fun ended(service: SmsBackgroundJobService) {
        if (running === service) running = null
    }

    @Synchronized
    fun poison(context: Context) {
        poisoned = true
        val p = prefs(context)
        // Do not overwrite an explicit or legacy suspension with a recoverable one.
        if (!p.getBoolean("paused", false)) {
            check(p.edit().putBoolean("paused", true).putString("pauseReason", "interrupted").commit())
        }
    }

    fun bind(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                synchronized(this) {
                when (call.method) {
                    "configure" -> {
                        configurePath(context, requireNotNull(call.argument<String>("path")))
                        result.success(null)
                    }
                    "schedule" -> result.success(schedule(context))
                    "acquire" -> {
                        val admitted = !blocked(context) && running == null && foregroundOwner == null
                        if (admitted) foregroundOwner = messenger
                        result.success(admitted)
                    }
                    "release" -> {
                        check(foregroundOwner === messenger)
                        foregroundOwner = null
                        result.success(null)
                    }
                    "suspend" -> suspendForRestore(context, result)
                    "resume" -> {
                        check(!poisoned && running == null && foregroundOwner == null)
                        val path = prefs(context).getString("path", null)
                        check(path != null && !File("$path.restore-marker").exists())
                        check(prefs(context).edit().putBoolean("paused", false).remove("pauseReason").commit())
                        result.success(schedule(context))
                    }
                    "status" -> result.success(mapOf("paused" to blocked(context),
                        "running" to (running != null), "foregroundBusy" to (foregroundOwner != null)))
                    else -> result.notImplemented()
                }
                }
            } catch (_: Exception) {
                result.error("sms_runtime_unavailable", "SMS runtime operation unavailable", null)
            }
        }
    }

    @Synchronized
    fun detach(messenger: BinaryMessenger) {
        // Do not release an unknown in-flight foreground database operation.
        // A new process resets the lease; restore must fail closed in this process.
        if (foregroundOwner === messenger) poisoned = true
    }

    @Synchronized
    fun configurePath(context: Context, path: String) {
        val file = File(path).canonicalFile
        val root = File(context.applicationInfo.dataDir).canonicalFile
        require(file.path.startsWith(root.path + File.separator) && file.name == "planact.sqlite")
        check(prefs(context).edit().putString("path", file.path).commit())
    }

    @Synchronized
    fun suspendForRestore(context: Context, result: MethodChannel.Result, after: (() -> Unit)? = null) {
        // Admission and pause installation share the same monitor as acquire/begin.
        // A rejected restore has no durable side effect and cannot strand scanning.
        if (poisoned || running != null || foregroundOwner != null) {
            result.error("sms_runtime_busy", "Wait for SMS work to close and retry restore", null)
            return
        }
        check(prefs(context).edit().putBoolean("paused", true).putString("pauseReason", "restore").commit())
        context.getSystemService(JobScheduler::class.java).cancel(JOB_ID)
        if (after != null) after() else result.success(null)
    }
}
