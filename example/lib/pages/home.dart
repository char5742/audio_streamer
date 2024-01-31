import 'package:audio_streamer_example/providers/audio.dart';
import 'package:audio_streamer_example/providers/recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'components.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useStreamController<List<int>>();
    final spots = useState<List<int>>([]);
    final echoCancellation = useState<bool>(false);
    useOnAppLifecycleStateChange((beforeState, currState) {
      if (currState == AppLifecycleState.resumed) {
        ref.read(recoderProvider).record(controller, echoCancellation.value);
      } else if (currState == AppLifecycleState.paused) {
        ref.read(recoderProvider).stopRecorder();
      }
    });
    useEffect(() {
      ref
          .read(recoderProvider)
          .init()
          .then((value) => ref.read(recoderProvider).record(controller));
      final subscription = controller.stream.listen((event) {
        final buffer = event.toList();
        spots.value = buffer;
      });
      return subscription.cancel;
    }, []);
    return Scaffold(
      body: Column(
        children: [
          Waveform(audioData: spots.value),
          IconButton(
            onPressed: () async {
              echoCancellation.value = !echoCancellation.value;
              await ref.read(recoderProvider).stopRecorder();
              await ref
                  .read(recoderProvider)
                  .record(controller, echoCancellation.value);
            },
            icon: Icon(
              Icons.power_settings_new,
              color: echoCancellation.value ? Colors.green : Colors.black,
              size: 64,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () async {
              await ref.read(audioServiceProvider).play();
            },
            child: const Text("play"),
          )
        ],
      ),
    );
  }
}
