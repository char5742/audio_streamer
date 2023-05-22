import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'audio_streamer_method_channel.dart';

abstract class AudioStreamerPlatform extends PlatformInterface {
  /// Constructs a AudioStreamerPlatform.
  AudioStreamerPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioStreamerPlatform _instance = MethodChannelAudioStreamer();

  /// The default instance of [AudioStreamerPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudioStreamer].
  static AudioStreamerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AudioStreamerPlatform] when
  /// they register themselves.
  static set instance(AudioStreamerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<List<int>> get audioStream {
    throw UnimplementedError('audioStream has not been implemented.');
  }

  Future<void> startRecording() {
    throw UnimplementedError('startRecording() has not been implemented.');
  }

  Future<void> stopRecording() {
    throw UnimplementedError('stopRecording() has not been implemented.');
  }
}
