import Flutter

public class AudioStreamerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private let audioEngineManager = AudioEngineManager()

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
            if let args = call.arguments as? [String: Any],
               let recordingMode = args["recordingMode"] as? Int
            {
                audioEngineManager.startRecording(
                    recordingMode: RecordingMode(rawValue: recordingMode) ?? .normal
                ) { data in
                    self.eventSink?(data)
                }
            }
            result(nil)

        case "stopRecording":
            audioEngineManager.stopRecording()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
