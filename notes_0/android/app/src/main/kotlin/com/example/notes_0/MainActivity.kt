package com.example.notes_0

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.notes_0/recording"
    private lateinit var recordingManager: RecordingManager
    private var methodChannel: MethodChannel? = null

    private val uploadTriggerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.example.notes_0.UPLOAD_TRIGGER") {
                // Notify Flutter to perform upload
                methodChannel?.invokeMethod("onUploadTrigger", null)
            }
        }
    }

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        recordingManager = RecordingManager(this)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        if (checkPermissions()) {
                            startRecordingService()
                            result.success(true)
                        } else {
                            requestPermissions()
                            result.error("PERMISSION_DENIED", "Permissions not granted", null)
                        }
                    }
                    "stopService" -> {
                        stopRecordingService()
                        result.success(true)
                    }
                    "checkPermissions" -> {
                        result.success(checkPermissions())
                    }
                    "requestPermissions" -> {
                        requestPermissions()
                        result.success(null)
                    }
                    "getAllRecordings" -> {
                        val recordings = recordingManager.getAllRecordings()
                        val recordingsList = recordings.map { file ->
                            mapOf(
                                "filePath" to file.absolutePath,
                                "fileName" to file.name,
                                "timestamp" to file.lastModified(),
                                "size" to file.length()
                            )
                        }
                        result.success(recordingsList)
                    }
                    "deleteRecording" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath != null) {
                            val deleted = recordingManager.deleteRecording(filePath)
                            result.success(deleted)
                        } else {
                            result.error("INVALID_ARGUMENT", "File path is required", null)
                        }
                    }
                    "saveApiEndpoint" -> {
                        val endpoint = call.argument<String>("endpoint")
                        if (endpoint != null) {
                            val prefs = getSharedPreferences("notes_0_prefs", MODE_PRIVATE)
                            prefs.edit().putString("api_endpoint", endpoint).apply()
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGUMENT", "Endpoint is required", null)
                        }
                    }
                    "getApiEndpoint" -> {
                        val prefs = getSharedPreferences("notes_0_prefs", MODE_PRIVATE)
                        val endpoint = prefs.getString("api_endpoint", "")
                        result.success(endpoint)
                    }
                    "triggerUpload" -> {
                        AudioUploadWorker.scheduleUpload(this)
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun checkPermissions(): Boolean {
        val permissions = mutableListOf(
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.VIBRATE,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        return permissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestPermissions() {
        val permissions = mutableListOf(
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.VIBRATE,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        ActivityCompat.requestPermissions(
            this,
            permissions.toTypedArray(),
            PERMISSION_REQUEST_CODE
        )
    }

    private fun startRecordingService() {
        val serviceIntent = Intent(this, VolumeButtonRecordingService::class.java).apply {
            action = VolumeButtonRecordingService.ACTION_START_SERVICE
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopRecordingService() {
        val serviceIntent = Intent(this, VolumeButtonRecordingService::class.java).apply {
            action = VolumeButtonRecordingService.ACTION_STOP_SERVICE
        }
        startService(serviceIntent)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }

            // Notify Flutter about permission result
            val channel = MethodChannel(
                flutterEngine?.dartExecutor?.binaryMessenger ?: return,
                channelName
            )
            channel.invokeMethod("onPermissionsResult", allGranted)
        }
    }

    override fun onResume() {
        super.onResume()
        val filter = IntentFilter("com.example.notes_0.UPLOAD_TRIGGER")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(uploadTriggerReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(uploadTriggerReceiver, filter)
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            unregisterReceiver(uploadTriggerReceiver)
        } catch (e: IllegalArgumentException) {
            // Receiver not registered, ignore
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        recordingManager.release()
    }
}
