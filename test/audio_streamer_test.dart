import 'package:flutter_test/flutter_test.dart';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:audio_streamer/audio_streamer_platform_interface.dart';
import 'package:audio_streamer/audio_streamer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudioStreamerPlatform
    with MockPlatformInterfaceMixin
    implements AudioStreamerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AudioStreamerPlatform initialPlatform = AudioStreamerPlatform.instance;

  test('$MethodChannelAudioStreamer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAudioStreamer>());
  });

  test('getPlatformVersion', () async {
    AudioStreamer audioStreamerPlugin = AudioStreamer();
    MockAudioStreamerPlatform fakePlatform = MockAudioStreamerPlatform();
    AudioStreamerPlatform.instance = fakePlatform;

    expect(await audioStreamerPlugin.getPlatformVersion(), '42');
  });
}
