package com.example.notes_0

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

class VolumeButtonAccessibilityService : AccessibilityService() {

    private lateinit var recordingManager: RecordingManager
    private lateinit var vibrator: Vibrator
    private var volumeDownTime = 0L
    private val longPressThreshold = 1000L // 1 second
    private var isRecording = false
    private var longPressDetected = false

    override fun onServiceConnected() {
        super.onServiceConnected()

        recordingManager = RecordingManager(this)
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        // Notify that service is ready
        sendBroadcast(Intent("com.example.notes_0.ACCESSIBILITY_SERVICE_CONNECTED"))
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We don't need to handle accessibility events for this use case
        // We only care about hardware key events
    }

    override fun onInterrupt() {
        // Called when the system wants to interrupt the feedback this service is providing
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        // Only intercept Volume Up button
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            when (event.action) {
                KeyEvent.ACTION_DOWN -> {
                    handleVolumeDown()
                    return true // Consume the event to prevent volume change
                }
                KeyEvent.ACTION_UP -> {
                    handleVolumeUp()
                    return true // Consume the event
                }
            }
        }
        return super.onKeyEvent(event)
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

    override fun onDestroy() {
        super.onDestroy()
        if (isRecording) {
            stopRecordingAudio()
        }
        recordingManager.release()

        // Notify that service stopped
        sendBroadcast(Intent("com.example.notes_0.ACCESSIBILITY_SERVICE_DISCONNECTED"))
    }
}
