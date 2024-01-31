import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_streamer_platform_interface.dart';

/// An implementation of [AudioStreamerPlatform] that uses method channels.
class MethodChannelAudioStreamer extends AudioStreamerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel =
      const MethodChannel('com.example.audio_streamer/methods');
  @visibleForTesting
  final eventChannel = const EventChannel('com.example.audio_streamer/events');
  @override
  Stream<List<int>> get audioStream {
    return eventChannel.receiveBroadcastStream().map((event) {
      return event.cast<int>();
    });
  }

  @override
  Future<void> startRecording(int recordingMode) async {
    await methodChannel.invokeMethod<void>('startRecording', {
      'recordingMode': recordingMode,
    });
  }

  @override
  Future<void> stopRecording() async {
    await methodChannel.invokeMethod<void>('stopRecording');
  }
}
