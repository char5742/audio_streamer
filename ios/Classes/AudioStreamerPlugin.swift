import AVFoundation
import Flutter

public class AudioStreamerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private let audioEngine = AVAudioEngine()

  override public
    init()
  {
    super.init()
    do {
      // FIXME: This throws an error:
      // from AU (0x101b0a040): auou/vpio/appl, render err: -1
      // throwing -1
      try audioEngine.inputNode.setVoiceProcessingEnabled(true)
    } catch {
      print("Could not enable voice processing \(error)")
    }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AudioStreamerPlugin()

    let methodChannel = FlutterMethodChannel(
      name: "com.example.audio_streamer/methods", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(
      name: "com.example.audio_streamer/events", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startRecording":
      self.startRecording()
      result(nil)
    case "stopRecording":
      self.stopRecording()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  private func startRecording() {
    let inputNode = audioEngine.inputNode

    let inputFormat = inputNode.outputFormat(forBus: 0)
    let mixer = AVAudioMixerNode()
    audioEngine.attach(mixer)
    audioEngine.connect(inputNode, to: mixer, format: inputFormat)
    mixer.outputVolume = 50.0
    let format16K = AVAudioFormat(
      commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1,
      interleaved: true)!
    let converter = AVAudioConverter(from: inputFormat, to: format16K)!
    let sampleRateRatio = 16000 / inputFormat.sampleRate
    mixer.installTap(
      onBus: 0, bufferSize: 8196, format: inputFormat
    ) {
      (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
      guard let eventSink = self.eventSink else {
        return
      }

      let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameCapacity) * sampleRateRatio)

      let newBuffer = AVAudioPCMBuffer(
        pcmFormat: format16K, frameCapacity: outputFrameCapacity)!

      let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
        outStatus.pointee = .haveData
        return buffer
      }

      converter.convert(to: newBuffer, error: nil, withInputFrom: inputBlock)
      eventSink(newBuffer.data())
    }

    audioEngine.prepare()

    do {
      try audioEngine.start()
    } catch {
      print("Error starting audio engine: \(error)")
    }
  }

  private func stopRecording() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    self.eventSink = nil
  }
}

extension AVAudioPCMBuffer {
  func data() -> Data {
    let channelCount = 1  // Given PCMBuffer channel count is 1
    let channels = UnsafeBufferPointer(start: self.int16ChannelData, count: channelCount)
    let ch0Data =
      NSData(
        bytes: channels[0],
        length: Int(self.frameCapacity * self.format.streamDescription.pointee.mBytesPerFrame))
      as Data
    return ch0Data
  }
}
