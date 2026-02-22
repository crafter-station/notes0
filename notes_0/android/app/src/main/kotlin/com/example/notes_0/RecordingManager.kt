package com.example.notes_0

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

class RecordingManager(private val context: Context) {
    private var mediaRecorder: MediaRecorder? = null
    private var currentRecordingFile: File? = null
    private var isRecording = false

    companion object {
        private const val AUDIO_FORMAT = ".m4a"
        private const val RECORDINGS_DIR = "recordings"
    }

    fun startRecording(): String? {
        if (isRecording) {
            return null
        }

        return try {
            val recordingsDir = getRecordingsDirectory()
            val fileName = generateFileName()
            val file = File(recordingsDir, fileName)

            currentRecordingFile = file

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(context)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(128000)
                setAudioSamplingRate(44100)
                setOutputFile(file.absolutePath)

                try {
                    prepare()
                    start()
                    isRecording = true
                } catch (e: IOException) {
                    release()
                    throw e
                }
            }

            file.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            mediaRecorder?.release()
            mediaRecorder = null
            currentRecordingFile = null
            null
        }
    }

    fun stopRecording(): String? {
        if (!isRecording) {
            return null
        }

        return try {
            mediaRecorder?.apply {
                stop()
                release()
            }
            val filePath = currentRecordingFile?.absolutePath

            mediaRecorder = null
            currentRecordingFile = null
            isRecording = false

            filePath
        } catch (e: Exception) {
            e.printStackTrace()
            mediaRecorder?.release()
            mediaRecorder = null
            currentRecordingFile = null
            isRecording = false
            null
        }
    }

    fun isCurrentlyRecording(): Boolean = isRecording

    fun getRecordingsDirectory(): File {
        val dir = File(context.getExternalFilesDir(null), RECORDINGS_DIR)
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }

    fun getAllRecordings(): List<File> {
        val dir = getRecordingsDirectory()
        return dir.listFiles()?.filter { it.extension == "m4a" }?.sortedByDescending { it.lastModified() }
            ?: emptyList()
    }

    fun deleteRecording(filePath: String): Boolean {
        val file = File(filePath)
        return if (file.exists()) {
            file.delete()
        } else {
            false
        }
    }

    private fun generateFileName(): String {
        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss_SSS", Locale.US)
            .format(Date())
        return "recording_${timestamp}${AUDIO_FORMAT}"
    }

    fun release() {
        if (isRecording) {
            stopRecording()
        }
        mediaRecorder?.release()
        mediaRecorder = null
    }
}
