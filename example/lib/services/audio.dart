import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final player = AudioPlayer()
    ..setAudioContext(
      const AudioContext(
        android: AudioContextAndroid(
          audioMode: AndroidAudioMode.inCommunication
        ),
      ),
    );

  Future<void> play() async {
    String outputPath = '${(await getTemporaryDirectory()).path}/output.wav';
    await player.setSourceDeviceFile(outputPath);
    await player.resume();
  }
}
