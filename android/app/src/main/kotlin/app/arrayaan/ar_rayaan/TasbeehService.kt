package app.arrayaan.ar_rayaan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.VolumeProvider
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.KeyEvent

/**
 * Counts with the hardware buttons while the screen is off.
 *
 * How it works, and what it cannot promise: an active MediaSession that
 * reports "playing" (backed by a silent audio stream) and owns a remote
 * VolumeProvider is where Android sends the volume keys, also with the
 * screen off. Volume up is +1, volume down is -1. A headset button
 * (HEADSETHOOK / PLAY_PAUSE) is +1. The count is kept in [TasbeehCounter]
 * and shown in an ongoing notification; Dart collects it when it is alive.
 * Some phone makers limit background key handling, so this can differ
 * between devices.
 */
class TasbeehService : Service() {
    private var session: MediaSession? = null
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var silenceRunning = false
    private var silenceThread: Thread? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        TasbeehBridge.service = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ensureChannel()
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        startSession()
        startSilence()
        // If the system kills the process the counting stops; the app starts
        // it again when the screen is opened with the switch still on.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopSilence()
        try {
            session?.isActive = false
            session?.release()
        } catch (e: Exception) {
            // Already released.
        }
        session = null
        TasbeehBridge.service = null
        super.onDestroy()
    }

    // ---- Media session -------------------------------------------------

    @Suppress("DEPRECATION")
    private fun startSession() {
        if (session != null) return
        val s = MediaSession(this, "ArRayaanTasbeeh")
        s.setFlags(
            MediaSession.FLAG_HANDLES_MEDIA_BUTTONS or
                MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS,
        )
        s.setCallback(
            object : MediaSession.Callback() {
                override fun onMediaButtonEvent(mediaButtonIntent: Intent): Boolean {
                    val ev: KeyEvent? =
                        if (Build.VERSION.SDK_INT >= 33) {
                            mediaButtonIntent.getParcelableExtra(
                                Intent.EXTRA_KEY_EVENT,
                                KeyEvent::class.java,
                            )
                        } else {
                            mediaButtonIntent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
                        }
                    if (ev == null) return false
                    val isHeadsetKey =
                        ev.keyCode == KeyEvent.KEYCODE_HEADSETHOOK ||
                            ev.keyCode == KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
                    if (!isHeadsetKey) return false
                    if (ev.action == KeyEvent.ACTION_DOWN && ev.repeatCount == 0) {
                        onPress(1)
                    }
                    return true
                }
            },
        )
        s.setPlaybackState(
            PlaybackState.Builder()
                .setActions(
                    PlaybackState.ACTION_PLAY or
                        PlaybackState.ACTION_PAUSE or
                        PlaybackState.ACTION_PLAY_PAUSE,
                )
                .setState(PlaybackState.STATE_PLAYING, 0L, 1.0f)
                .build(),
        )
        // The remote volume provider is what receives the volume keys.
        s.setPlaybackToRemote(
            object : VolumeProvider(VolumeProvider.VOLUME_CONTROL_RELATIVE, 100, 50) {
                override fun onAdjustVolume(direction: Int) {
                    if (direction > 0) {
                        onPress(1)
                    } else if (direction < 0) {
                        onPress(-1)
                    }
                }
            },
        )
        s.isActive = true
        session = s
    }

    /** One button press. Called on a binder thread, so hop to main. */
    private fun onPress(delta: Int) {
        val snap = TasbeehCounter.press(applicationContext, delta)
        main.post {
            buzz(if (snap.reachedTarget) 400L else if (delta > 0) 30L else 15L)
            notifyCount()
            TasbeehBridge.ping()
        }
        keepAwakeBriefly()
    }

    @Suppress("DEPRECATION")
    private fun keepAwakeBriefly() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            val lock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ar_rayaan:tasbeeh")
            lock.acquire(3000L)
        } catch (e: Exception) {
            // Counting still works without it.
        }
    }

    @Suppress("DEPRECATION")
    private fun buzz(ms: Long) {
        try {
            val vibrator: Vibrator =
                if (Build.VERSION.SDK_INT >= 31) {
                    (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager)
                        .defaultVibrator
                } else {
                    getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                }
            if (Build.VERSION.SDK_INT >= 26) {
                vibrator.vibrate(
                    VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE),
                )
            } else {
                vibrator.vibrate(ms)
            }
        } catch (e: Exception) {
            // No vibrator, or not allowed right now.
        }
    }

    // ---- Silent audio (keeps the media session "playing") -------------

    private fun startSilence() {
        if (silenceRunning) return
        try {
            val rate = 8000
            val minBuf = AudioTrack.getMinBufferSize(
                rate,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
            )
            if (minBuf <= 0) return
            val track = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(rate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build(),
                )
                .setBufferSizeInBytes(minBuf)
                .build()
            track.play()
            silenceRunning = true
            val t = Thread {
                val zeros = ByteArray(minBuf)
                while (silenceRunning) {
                    val n = track.write(zeros, 0, zeros.size)
                    if (n < 0) break
                }
                try {
                    track.stop()
                } catch (e: Exception) {
                    // Already stopped.
                }
                track.release()
            }
            t.isDaemon = true
            t.start()
            silenceThread = t
        } catch (e: Exception) {
            // Without the silent stream some phones will not route the
            // buttons; the notification still works.
            silenceRunning = false
        }
    }

    private fun stopSilence() {
        silenceRunning = false
        silenceThread = null
    }

    // ---- Notification ---------------------------------------------------

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                nm.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "Tasbeeh counter",
                        NotificationManager.IMPORTANCE_LOW,
                    ),
                )
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun buildNotification(): Notification {
        val snap = TasbeehCounter.snapshot(applicationContext)
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0),
        )
        val builder =
            if (Build.VERSION.SDK_INT >= 26) {
                Notification.Builder(this, CHANNEL_ID)
            } else {
                Notification.Builder(this)
            }
        builder
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle("Tasbeeh counter")
            .setContentText("${snap.count} of ${snap.target}  ·  ${snap.rounds} rounds completed")
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
        return builder.build()
    }

    private fun notifyCount() {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildNotification())
        } catch (e: Exception) {
            // Notifications may be blocked; counting is unaffected.
        }
    }

    /** The app changed the count on screen: show it in the notification. */
    fun refreshNotification() = notifyCount()

    companion object {
        const val CHANNEL_ID = "tasbeeh_counter"
        const val NOTIFICATION_ID = 7301
    }
}
