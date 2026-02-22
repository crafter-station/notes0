package com.example.notes_0

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.*
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import android.view.KeyEvent

class VolumeButtonRecordingService : Service() {

    private lateinit var recordingManager: RecordingManager
    private lateinit var vibrator: Vibrator
    private lateinit var audioManager: AudioManager
    private var mediaSession: MediaSessionCompat? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private var volumeDownTime = 0L
    private val longPressThreshold = 1000L // 1 second
    private var isRecording = false
    private var longPressDetected = false

    private val binder = LocalBinder()

    companion object {
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "recording_service_channel"
        const val ACTION_START_SERVICE = "com.example.notes_0.START_SERVICE"
        const val ACTION_STOP_SERVICE = "com.example.notes_0.STOP_SERVICE"
    }

    inner class LocalBinder : Binder() {
        fun getService(): VolumeButtonRecordingService = this@VolumeButtonRecordingService
    }

    override fun onCreate() {
        super.onCreate()

        recordingManager = RecordingManager(this)
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        createNotificationChannel()
        setupMediaSession()
        requestAudioFocusForService()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                startForegroundService()
            }
            ACTION_STOP_SERVICE -> {
                stopForegroundService()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Voice Recording Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the app running to detect volume button presses"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun setupMediaSession() {
        mediaSession = MediaSessionCompat(this, "VolumeButtonRecorder").apply {
            setFlags(
                MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or
                MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
            )

            setPlaybackState(
                PlaybackStateCompat.Builder()
                    .setState(PlaybackStateCompat.STATE_PLAYING, 0, 1.0f)
                    .build()
            )

            setCallback(object : MediaSessionCompat.Callback() {
                override fun onMediaButtonEvent(mediaButtonEvent: Intent?): Boolean {
                    val keyEvent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        mediaButtonEvent?.getParcelableExtra(Intent.EXTRA_KEY_EVENT, KeyEvent::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        mediaButtonEvent?.getParcelableExtra(Intent.EXTRA_KEY_EVENT)
                    }

                    when (keyEvent?.keyCode) {
                        KeyEvent.KEYCODE_VOLUME_UP -> {
                            when (keyEvent.action) {
                                KeyEvent.ACTION_DOWN -> {
                                    handleVolumeDown()
                                    return true
                                }
                                KeyEvent.ACTION_UP -> {
                                    handleVolumeUp()
                                    return true
                                }
                            }
                        }
                    }
                    return super.onMediaButtonEvent(mediaButtonEvent)
                }
            })

            isActive = true
        }
    }

    private fun requestAudioFocusForService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()

            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(audioAttributes)
                .setAcceptsDelayedFocusGain(true)
                .setWillPauseWhenDucked(false)
                .setOnAudioFocusChangeListener { focusChange ->
                    // Handle audio focus changes if needed
                }
                .build()

            audioManager.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                { },
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )
        }
    }

    private fun handleVolumeDown() {
        // Button pressed down - start timing
        volumeDownTime = System.currentTimeMillis()
        longPressDetected = false
    }

    private fun handleVolumeUp() {
        // Button released - check if it was held long enough
        val currentTime = System.currentTimeMillis()
        val pressDuration = currentTime - volumeDownTime

        if (pressDuration >= longPressThreshold && !longPressDetected) {
            // Long press detected (held for 1+ second)
            longPressDetected = true
            toggleRecording()
        }

        volumeDownTime = 0L
    }

    private fun toggleRecording() {
        if (isRecording) {
            stopRecordingAudio()
        } else {
            startRecordingAudio()
        }
    }

    private fun startRecordingAudio() {
        val filePath = recordingManager.startRecording()
        if (filePath != null) {
            isRecording = true
            vibratePattern(longArrayOf(0, 100)) // Short vibration
            updateNotification("Recording in progress...")

            // Notify Flutter
            sendBroadcast(Intent("com.example.notes_0.RECORDING_STARTED").apply {
                putExtra("filePath", filePath)
            })
        }
    }

    private fun stopRecordingAudio() {
        val filePath = recordingManager.stopRecording()
        if (filePath != null) {
            isRecording = false
            vibratePattern(longArrayOf(0, 100, 100, 100)) // Double vibration
            updateNotification("Ready to record")

            // Schedule upload via WorkManager
            AudioUploadWorker.scheduleUpload(this)

            // Notify Flutter
            sendBroadcast(Intent("com.example.notes_0.RECORDING_STOPPED").apply {
                putExtra("filePath", filePath)
            })
        }
    }

    private fun vibratePattern(pattern: LongArray) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }

    private fun startForegroundService() {
        val notification = createNotification("Ready to record")
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun stopForegroundService() {
        if (isRecording) {
            stopRecordingAudio()
        }
        mediaSession?.release()
        mediaSession = null
        recordingManager.release()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotification(contentText: String): Notification {
        val stopIntent = Intent(this, VolumeButtonRecordingService::class.java).apply {
            action = ACTION_STOP_SERVICE
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Voice Recorder Active")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_delete, "Stop Service", stopPendingIntent)
            .build()
    }

    private fun updateNotification(contentText: String) {
        val notification = createNotification(contentText)
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        super.onDestroy()

        // Release audio focus
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let {
                audioManager.abandonAudioFocusRequest(it)
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus { }
        }

        mediaSession?.release()
        recordingManager.release()
    }
}
