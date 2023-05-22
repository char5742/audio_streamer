package com.example.audio_streamer

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import androidx.annotation.NonNull
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.util.concurrent.Executors

class AudioStreamerPlugin : FlutterPlugin, EventChannel.StreamHandler, MethodCallHandler {
  
  private var methodChannel: MethodChannel? = null
  private val executor = Executors.newSingleThreadExecutor()
  private var eventSink: EventChannel.EventSink? = null
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    val messenger = binding.binaryMessenger
    val channel = EventChannel(messenger, "com.example.audio_streamer/events")
    channel.setStreamHandler(this)

    methodChannel = MethodChannel(messenger, "com.example.audio_streamer/methods")
    methodChannel?.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    executor.shutdownNow()
  }

  override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) {
    this.eventSink = eventSink
    executor.execute {
      startRecording()
    }
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  private fun startRecording() {
    val sampleRate = 16000
    val channelConfig = AudioFormat.CHANNEL_IN_MONO
    val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    val minBufSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
    val audioRecord = AudioRecord(MediaRecorder.AudioSource.VOICE_COMMUNICATION, sampleRate, channelConfig, audioFormat, minBufSize)
    var acousticEchoCanceler: AcousticEchoCanceler? = null
    // Initialize AcousticEchoCanceler for the AudioRecord instance
    if (AcousticEchoCanceler.isAvailable()) {
      acousticEchoCanceler = AcousticEchoCanceler.create(audioRecord.audioSessionId)
      acousticEchoCanceler.enabled = true
    }

    val audioData = ByteArray(minBufSize)
    audioRecord.startRecording()

    while (eventSink != null) {
      val readSize = audioRecord.read(audioData, 0, audioData.size)
      if (readSize > 0) {
        mainHandler.post {
          eventSink?.success(audioData)
        }
      }
    }
    // Cleanup
    acousticEchoCanceler?.release()
    acousticEchoCanceler = null
    audioRecord.stop()
    audioRecord.release()
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startRecording" -> {
                executor.execute {
                    startRecording()
                }
                result.success(null)
            }
            "stopRecording" -> {
                eventSink = null
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
