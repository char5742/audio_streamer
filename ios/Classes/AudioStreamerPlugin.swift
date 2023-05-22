import Flutter
import AVFoundation

public class AudioStreamerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler  {
   private var eventSink: FlutterEventSink?
    private let audioEngine = AVAudioEngine()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftAudioStreamerPlugin()

        let methodChannel = FlutterMethodChannel(name: "com.example.audio_streamer/methods", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(name: "com.example.audio_streamer/events", binaryMessenger: registrar.messenger())
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

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    private func startRecording() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            guard let eventSink = self.eventSink else {
                return
            }
            
            let audioData = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
            eventSink(audioData)
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
