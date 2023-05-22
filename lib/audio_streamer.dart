import 'dart:async';

import 'package:flutter/services.dart';

import 'audio_streamer_platform_interface.dart';

class AudioStreamer {
  AudioStreamer._();

  static final AudioStreamer instance = AudioStreamer._();
  Future<void> startRecording() async {
    try {
      await AudioStreamerPlatform.instance.startRecording();
    } on PlatformException {
      throw 'Failed to start audio stream.';
    }
  }

  Future<void> stopRecording() async {
    try {
      await AudioStreamerPlatform.instance.stopRecording();
    } on PlatformException {
      throw 'Failed to stop audio stream.';
    }
  }

  Stream<List<int>> get audioStream =>
      AudioStreamerPlatform.instance.audioStream;
}
