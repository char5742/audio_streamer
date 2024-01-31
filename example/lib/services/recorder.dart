import 'dart:async';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:permission_handler/permission_handler.dart';

class RecorderService {
  final recorder = AudioStreamer.instance;
  final sampleRate = 16000;
  final frameSize = 40; // 80ms

  final int bitsPerSample = 16;

  final int numChannels = 1;

  bool _isInitialized = false;

  StreamSubscription<List<int>>? recordingDataSubscription;

  Future<void> init() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
    _isInitialized = true;
  }

  Future<void> record(StreamController<List<int>> controller,
      [bool echoCancellation = true]) async {
    assert(_isInitialized);
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      // Echo cancellation is enabled on iOS by using voiceChat.
      avAudioSessionMode: echoCancellation
          ? AVAudioSessionMode.voiceChat
          : AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    ));
    await recorder.startRecording(echoCancellation ? 7 : 0);
    recordingDataSubscription = recorder.audioStream.listen((buffer) async {
      final data = _transformBuffer(buffer);
      if (data.isEmpty) return;
      controller.add(data);
    });
  }

  Future<void> stopRecorder() async {
    await recorder.startRecording();
    if (recordingDataSubscription != null) {
      await recordingDataSubscription?.cancel();
      recordingDataSubscription = null;
    }
  }

  Int16List _transformBuffer(List<int> buffer) {
    final bytes = Uint8List.fromList(buffer);
    return Int16List.view(bytes.buffer);
  }
}
