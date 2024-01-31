import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

class AudioService {
  AudioService() {
    player = AudioPlayer();
  }
  late AudioPlayer player;

  Future<void> play() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final file = result.files.single;
    await player.play(DeviceFileSource(file.path!));
  }
}
