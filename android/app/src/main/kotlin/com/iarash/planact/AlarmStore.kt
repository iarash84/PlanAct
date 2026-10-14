package com.iarash.planact

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.os.Build
import java.io.File
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId

/** Native persistence adapter for the alarm commands; no Flutter engine is needed.
 * All admissions take the SQLite writer lock and compare fresh durable ownership.
 * Enum indices and epoch-second timestamps are the v18 Drift storage contract.
 */
internal class AlarmStore(private val context: Context) {
    companion object {
        val lock = Any()
        // Process-local permission for the host's validated restore rebuild.
        // A crashed process never inherits access to an uncommitted candidate.
        private var recoveryAccess = false
    }
    private val prefs = context.getSharedPreferences("planact_alarm_v1", Context.MODE_PRIVATE)
    private val manager get() = context.getSystemService(AlarmManager::class.java)

    data class Alarm(val id: String, val at: Long, val status: Int)

    fun configure(path: String, version: Int) = synchronized(lock) {
        val file = File(path).canonicalFile
        val root = File(context.applicationInfo.dataDir).canonicalFile
        require(file.path.startsWith(root.path + File.separator) && file.name == "planact.sqlite")
        require(version == 18)
        recoveryAccess = File(file.path + ".restore-marker").exists()
        check(prefs.edit().putString("path", file.path).putBoolean("paused", false).commit())
    }

    private fun <T> transaction(action: (SQLiteDatabase) -> T): T = synchronized(lock) {
        check(!prefs.getBoolean("paused", false))
        val file = File(checkNotNull(prefs.getString("path", null)))
        check(file.isFile && (!File(file.path + ".restore-marker").exists() || recoveryAccess))
        SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE or
            SQLiteDatabase.NO_LOCALIZED_COLLATORS).use { db ->
            db.rawQuery("PRAGMA busy_timeout = 3000", null).use { it.moveToFirst() }
            db.beginTransaction()
            try {
                db.rawQuery("SELECT value FROM schema_metadata WHERE key='schema_version'", null).use {
                    check(it.moveToFirst() && it.getString(0) == "18")
                }
                // Explicit writer admission, shared with the Dart commands.
                db.execSQL("UPDATE schema_metadata SET value=value WHERE key='schema_version'")
                val value = action(db)
                db.setTransactionSuccessful()
                value
            } finally { db.endTransaction() }
        }
    }

    private fun find(db: SQLiteDatabase, id: String): Alarm? {
        db.rawQuery("""
            SELECT i.id, CASE WHEN i.status=3 THEN i.snoozed_until ELSE i.scheduled_at END, i.status,
                   r.anchor, r.offset_seconds, r.absolute_at, o.current_scheduled_value, i.scheduled_at
            FROM reminder_instances i JOIN reminder_rules r ON r.id=i.rule_id
            JOIN occurrences o ON o.id=i.occurrence_id
            JOIN commitment_cycles c ON c.id=o.cycle_id JOIN commitments p ON p.id=c.commitment_id
            JOIN schema_metadata m ON m.key='reminder_delivery_v1:instance:' || i.id
            JOIN schema_metadata rm ON rm.key='reminder_delivery_v1:rule:' || r.id
            WHERE i.id=? AND r.occurrence_id=o.id AND r.enabled=1
            AND m.value='alarm' AND rm.value='alarm'
            AND p.status=0 AND c.status=1 AND o.status NOT IN (2,3,4)
        """.trimIndent(), arrayOf(id)).use { cursor ->
            if (!cursor.moveToFirst() || cursor.isNull(1)) return null
            val expected = if (cursor.getInt(3) == 1) {
                if (cursor.isNull(5)) return null else cursor.getLong(5)
            } else {
                val value = cursor.getString(6)
                val start = when {
                    value.startsWith("instant:") -> Instant.parse(value.substring(8)).epochSecond
                    value.startsWith("local:") -> {
                        val parts = value.substring(6).split('T')
                        val date = parts[0].split('-').map(String::toInt)
                        val time = parts[1].split(':')
                        LocalDateTime.of(date[0], date[1], date[2], time[0].toInt(),
                            time[1].toInt(), time[2].substringBefore('.').toInt())
                            .atZone(ZoneId.systemDefault()).toEpochSecond()
                    }
                    else -> return null // A date-only occurrence has no invented clock time.
                }
                start + cursor.getLong(4)
            }
            if (cursor.getLong(7) != expected) return null
            return Alarm(cursor.getString(0), cursor.getLong(1), cursor.getInt(2))
        }
    }

    private fun pending(id: String, at: Long = 0): PendingIntent = PendingIntent.getBroadcast(
        context, 0, Intent(context, AlarmReceiver::class.java)
            .setAction("planact.alarm.FIRE").setData(Uri.parse("planact-alarm://fire/$id"))
            .putExtra("id", id).putExtra("at", at),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    fun available(): Boolean {
        AlarmNotifications.channel(context)
        return (Build.VERSION.SDK_INT < 31 || manager.canScheduleExactAlarms()) &&
            AlarmNotifications.enabled(context)
    }

    private fun enqueue(alarm: Alarm) {
        check(available())
        val ids = prefs.getStringSet("scheduled", emptySet())!!.toMutableSet()
        ids.add(alarm.id)
        check(prefs.edit().putStringSet("scheduled", ids).commit())
        val show = PendingIntent.getActivity(context, 0,
            Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        manager.setAlarmClock(AlarmManager.AlarmClockInfo(alarm.at * 1000, show),
            pending(alarm.id, alarm.at))
    }

    fun schedule(id: String, expectedAt: Long): Boolean = transaction { db ->
        val alarm = find(db, id) ?: return@transaction false
        if (alarm.status == 2) return@transaction true // Already delivered by the native receiver.
        if (alarm.status !in listOf(0, 3) || alarm.at != expectedAt ||
            alarm.at * 1000 <= System.currentTimeMillis()) return@transaction false
        enqueue(alarm)
        true
    }

    /** Claim exactly once. A duplicate/stale broadcast can never replay a ring. */
    fun claim(id: String, at: Long): Boolean = synchronized(lock) { transaction { db ->
        val alarm = find(db, id) ?: return@transaction false
        val now = System.currentTimeMillis() / 1000
        if (alarm.status !in listOf(0, 3) || alarm.at != at || at > now + 1 ||
            at < now - 300 || !available()) return@transaction false
        db.execSQL("UPDATE reminder_instances SET status=2, snoozed_until=NULL WHERE id=?", arrayOf(id))
        true
    }.also { claimed ->
        if (claimed) check(prefs.edit().putLong("ring:$id", at).commit())
    } }

    /** Explicit action: alters reminder intent only, never occurrence/financial state. */
    fun snooze(id: String, at: Long): Boolean = transaction { db ->
        if (prefs.getLong("ring:$id", -1) != at) return@transaction false
        val alarm = find(db, id) ?: return@transaction false
        if (alarm.status != 2) return@transaction false
        val until = System.currentTimeMillis() / 1000 + 600
        db.execSQL("UPDATE reminder_instances SET status=3, snoozed_until=? WHERE id=?", arrayOf<Any>(until, id))
        true
    }.also { changed ->
        if (changed) {
            clearRing(id)
            // Re-read after commit. Interruption leaves durable retry intent.
            transaction { db -> find(db, id)?.takeIf { it.status == 3 }?.let(::enqueue) }
        }
    }

    fun clearRing(id: String) { check(prefs.edit().remove("ring:$id").commit()) }

    fun cancel(id: String) = synchronized(lock) {
        manager.cancel(pending(id))
        clearRing(id)
        val ids = prefs.getStringSet("scheduled", emptySet())!!.toMutableSet()
        ids.remove(id)
        check(prefs.edit().putStringSet("scheduled", ids).commit())
        AlarmPlaybackService.remove(context, id)
        AlarmNotifications.cancel(context, id)
    }

    fun removeOrphans(active: Set<String>) = synchronized(lock) {
        for (id in prefs.getStringSet("scheduled", emptySet())!!.toSet()) {
            if (id !in active) cancel(id)
        }
    }

    // Flutter may have read an instance just before a native snooze committed.
    // Recheck before cleanup, so a stale inventory never cancels that new intent.
    fun cancelIfObsolete(id: String) = transaction { db ->
        val fresh = find(db, id)
        val future = fresh != null && fresh.status in listOf(0, 3) && fresh.at * 1000 > System.currentTimeMillis()
        val sounding = fresh?.status == 2 && prefs.contains("ring:$id")
        if (!future && !sounding) cancel(id)
    }

    fun removeObsolete(active: Set<String>) = synchronized(lock) {
        for (id in prefs.getStringSet("scheduled", emptySet())!!.toSet()) {
            if (id !in active) cancelIfObsolete(id)
        }
    }

    fun suspendAlarms() = synchronized(lock) {
        recoveryAccess = false
        check(prefs.edit().putBoolean("paused", true).commit())
        removeOrphans(emptySet())
    }

    fun rebuild() = transaction { db ->
        val ids = mutableListOf<String>()
        db.rawQuery("SELECT id FROM reminder_instances WHERE status IN (0,3)", null).use {
            while (it.moveToNext()) ids.add(it.getString(0))
        }
        val active = mutableSetOf<String>()
        for (id in ids) {
            val alarm = find(db, id) ?: continue
            if (alarm.at * 1000 > System.currentTimeMillis()) {
                enqueue(alarm)
                active.add(id)
            }
        }
        removeOrphans(active)
    }
}
