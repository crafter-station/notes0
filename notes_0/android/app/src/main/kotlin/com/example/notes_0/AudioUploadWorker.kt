package com.example.notes_0

import android.content.Context
import androidx.work.*
import java.util.concurrent.TimeUnit

class AudioUploadWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val WORK_NAME = "audio_upload_work"

        fun scheduleUpload(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.UNMETERED) // Wi-Fi only
                .build()

            val uploadRequest = OneTimeWorkRequestBuilder<AudioUploadWorker>()
                .setConstraints(constraints)
                .setBackoffCriteria(
                    BackoffPolicy.EXPONENTIAL,
                    10000, // 10 seconds minimum backoff
                    TimeUnit.MILLISECONDS
                )
                .build()

            WorkManager.getInstance(context)
                .enqueueUniqueWork(
                    WORK_NAME,
                    ExistingWorkPolicy.APPEND,
                    uploadRequest
                )
        }
    }

    override suspend fun doWork(): Result {
        // Notify Flutter that Wi-Fi is available and it should perform uploads
        notifyFlutterToUpload()
        return Result.success()
    }

    private fun notifyFlutterToUpload() {
        val intent = android.content.Intent("com.example.notes_0.UPLOAD_TRIGGER").apply {
            putExtra("trigger", "wifi_available")
        }
        applicationContext.sendBroadcast(intent)
    }
}
