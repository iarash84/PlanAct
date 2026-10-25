package com.iarash.planact

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import androidx.core.app.NotificationCompat
import java.io.File
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime

/** Handles USER_PRESENT without starting a long-running service or Flutter. */
class MorningReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_USER_PRESENT) return
        val result = goAsync()
        Thread {
            try { MorningReminderStore(context).tryShow() } catch (_: Exception) {
                // Morning delivery is opportunistic; durable reminders remain unaffected.
            } finally { result.finish() }
        }.start()
    }
}

private class MorningReminderStore(private val context: Context) {
    private val prefs = context.getSharedPreferences("planact_alarm_v1", Context.MODE_PRIVATE)

    fun tryShow() {
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 33 && !manager.areNotificationsEnabled()) return
        val path = prefs.getString("path", null) ?: return
        val dbFile = File(path)
        if (!dbFile.isFile) return
        val now = ZonedDateTime.now()
        val day = now.toLocalDate().toString()
        val minute = now.hour * 60 + now.minute
        SQLiteDatabase.openDatabase(path, null, SQLiteDatabase.OPEN_READWRITE or
            SQLiteDatabase.NO_LOCALIZED_COLLATORS).use { db ->
            db.beginTransaction()
            try {
                if (metadata(db, "morning_reminder_enabled_v1") != "true") return
                val window = metadata(db, "morning_reminder_window_v1")?.split(":")
                val start = window?.getOrNull(0)?.toIntOrNull() ?: 360
                val end = window?.getOrNull(1)?.toIntOrNull() ?: 600
                if (minute !in start until end) return
                if (metadata(db, "morning_reminder_sent_day_v1") == day) return
                if (!hasEligibleReminder(db, now.toLocalDate())) return
                db.execSQL("INSERT OR REPLACE INTO schema_metadata(key,value) VALUES(?,?)",
                    arrayOf("morning_reminder_sent_day_v1", day))
                db.setTransactionSuccessful()
            } finally { db.endTransaction() }
        }
        showNotification()
    }

    private fun metadata(db: SQLiteDatabase, key: String): String? =
        db.rawQuery("SELECT value FROM schema_metadata WHERE key=?", arrayOf(key)).use {
            if (it.moveToFirst()) it.getString(0) else null
        }

    private fun hasEligibleReminder(db: SQLiteDatabase, date: LocalDate): Boolean {
        // Drift stores DateTimeColumn instants as epoch seconds in this schema.
        val from = date.atStartOfDay(ZoneId.systemDefault()).toInstant().epochSecond
        val until = date.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant().epochSecond
        val sql = """
            SELECT 1 FROM reminder_instances i
            JOIN reminder_rules r ON r.id=i.rule_id
            JOIN occurrences o ON o.id=i.occurrence_id
            JOIN commitment_cycles c ON c.id=o.cycle_id
            JOIN commitments p ON p.id=c.commitment_id
            WHERE r.enabled=1 AND i.status IN (0,3)
              AND i.scheduled_at>=? AND i.scheduled_at<?
              AND p.status=0 AND c.status=1 AND o.status NOT IN (2,3,4)
            LIMIT 1
        """.trimIndent()
        return db.rawQuery(sql, arrayOf(from.toString(), until.toString())).use { it.moveToFirst() }
    }

    private fun showNotification() {
        val manager = context.getSystemService(NotificationManager::class.java)
        val channelId = "planact_morning_reminders"
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(
                channelId, "یادآوری صبحگاهی", NotificationManager.IMPORTANCE_DEFAULT))
        }
        val open = PendingIntent.getActivity(context, 0,
            Intent(context, MainActivity::class.java).setAction("planact.open.today"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(com.iarash.planact.R.drawable.ic_alarm_notification)
            .setContentTitle("یادآوری صبحگاهی پلن‌اکت")
            .setContentText("تعهدهای امروز شما نیاز به توجه دارند.")
            .setContentIntent(open)
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .build()
        manager.notify(0x504d, notification)
    }
}
