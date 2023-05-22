import 'package:audio_streamer_example/services/recorder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


final recoderProvider = Provider((ref) => RecorderService());