import AVFoundation

enum RecordingMode: Int {
    case normal = 0
    case echoCancel = 7
}

class AudioEngineManager {
    private let audioEngine = AVAudioEngine()
    private var eventSink: ((Data) -> Void)?
    private var isRecording = false

    func startRecording(recordingMode: RecordingMode, eventSink: @escaping (Data) -> Void) {
        setupAudioSetting(recordingMode: recordingMode)
        guard !isRecording else { return }
        self.eventSink = eventSink
        isRecording = true

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let format16K = AVAudioFormat(
            commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true
        )!
        let converter = AVAudioConverter(from: inputFormat, to: format16K)!
        let sampleRateRatio = 16000 / inputFormat.sampleRate

        inputNode.installTap(onBus: 0, bufferSize: 8196, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self, let eventSink = self.eventSink else { return }

            let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameCapacity) * sampleRateRatio)
            guard
                let newBuffer = AVAudioPCMBuffer(pcmFormat: format16K, frameCapacity: outputFrameCapacity)
            else { return }

            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            var error: NSError?
            converter.convert(to: newBuffer, error: &error, withInputFrom: inputBlock)

            if let error = error {
                print("Error during conversion: \(error)")
                self.stopRecording()
                self.restartAudioEngine()
                return
            }

            eventSink(newBuffer.data())
        }
        audioEngine.mainMixerNode.outputVolume = 0
        audioEngine.connect(inputNode, to: audioEngine.mainMixerNode, format: inputFormat)

        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: inputFormat)

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
            stopRecording()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        eventSink = nil
    }

    private func restartAudioEngine() {
        audioEngine.reset()
        do {
            try audioEngine.start()
        } catch {
            print("Error restarting audio engine: \(error)")
        }
    }

    private func setupAudioSetting(recordingMode: RecordingMode) {
        let isEchoCencel = recordingMode == .echoCancel
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord)
            try session.setActive(true)
            try session.setMode(isEchoCencel ? .voiceChat : .default)
            try audioEngine.inputNode.setVoiceProcessingEnabled(isEchoCencel)
        } catch {
            print("Could not enable voice processing: \(error)")
        }
    }
}

extension AVAudioPCMBuffer {
    func data() -> Data {
        let channelCount = 1 // Given PCMBuffer channel count is 1
        let channels = UnsafeBufferPointer(start: int16ChannelData, count: channelCount)
        return Data(
            bytes: channels[0],
            count: Int(frameCapacity * format.streamDescription.pointee.mBytesPerFrame)
        )
    }
}
