package com.iarash.planact

import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager

/** Exists only while alarms are sounding; never starts a Flutter engine. */
class AlarmPlaybackService : Service() {
    companion object {
        private var running: AlarmPlaybackService? = null
        fun remove(context: Context, id: String) {
            Handler(Looper.getMainLooper()).post { running?.removeRing(id) }
        }
        fun stopIfCurrent(context: Context, id: String, at: Long) {
            Handler(Looper.getMainLooper()).post {
                val service = running
                if (service?.rings?.get(id) == at) {
                    AlarmStore(context).clearRing(id)
                    service.removeRing(id)
                }
            }
        }
    }
    private val rings = linkedMapOf<String, Long>()
    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var focus: android.media.AudioFocusRequest? = null
    private var wake: PowerManager.WakeLock? = null
    private val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()

    override fun onCreate() { super.onCreate(); running = this }
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val id = intent?.getStringExtra("id") ?: run { stopSelf(); return START_NOT_STICKY }
        val at = intent.getLongExtra("at", -1)
        // Satisfy the foreground deadline before bounded SQLite admission.
        startForeground(AlarmNotifications.foregroundId, AlarmNotifications.build(this, id, at))
        try {
            if (!AlarmStore(this).claim(id, at)) {
                updateOrStop()
                return START_NOT_STICKY
            }
            rings[id] = at
            updateOrStop()
            if (player == null) startSound()
            else wake?.acquire(125_000)
            handler.postDelayed({
                if (rings[id] == at) {
                    AlarmStore(this).clearRing(id)
                    removeRing(id)
                }
            }, 120_000)
        } catch (_: Exception) {
            AlarmNotifications.failure(this, id)
            removeRing(id)
        }
        return START_NOT_STICKY
    }

    private fun startSound() {
        val audio = getSystemService(AudioManager::class.java)
        if (android.os.Build.VERSION.SDK_INT >= 26) {
            focus = android.media.AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(attributes).setOnAudioFocusChangeListener { change ->
                    if (change == AudioManager.AUDIOFOCUS_LOSS) stopSelf()
                }.build()
            check(audio.requestAudioFocus(focus!!) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
        }
        wake = getSystemService(PowerManager::class.java).newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK, "planact:alarm-playback").apply {
                setReferenceCounted(false)
                acquire(125_000)
            }
        player = MediaPlayer()
        player!!.apply {
            setAudioAttributes(attributes)
            setDataSource(this@AlarmPlaybackService, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            isLooping = true
            setOnErrorListener { _, _, _ -> stopSelf(); true }
            prepare()
            start()
        }
    }

    private fun removeRing(id: String) {
        rings.remove(id)
        AlarmStore(this).clearRing(id)
        AlarmNotifications.cancel(this, id)
        updateOrStop()
    }

    private fun updateOrStop() {
        if (rings.isEmpty()) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        } else {
            val first = rings.entries.first()
            startForeground(AlarmNotifications.foregroundId, AlarmNotifications.build(this, first.key, first.value))
            val notifications = getSystemService(android.app.NotificationManager::class.java)
            for ((id, at) in rings) {
                if (id != first.key) notifications.notify(id, 0, AlarmNotifications.build(this, id, at))
                else notifications.cancel(id, 0)
            }
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        player?.release()
        player = null
        focus?.let { getSystemService(AudioManager::class.java).abandonAudioFocusRequest(it) }
        if (wake?.isHeld == true) wake?.release()
        for (id in rings.keys) {
            AlarmNotifications.cancel(this, id)
            AlarmStore(this).clearRing(id)
        }
        rings.clear()
        running = null
        super.onDestroy()
    }
}
