import Foundation
import AVFoundation
import Combine
import Speech

@MainActor
final class TopMissionSpeechRecognizer: ObservableObject {
    @Published private(set) var isRecording = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?

    init(locale: Locale = .autoupdatingCurrent) {
        recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    }

    func toggleRecording(onText: @escaping (String) -> Void) {
        if isRecording {
            stopRecording()
            return
        }

        Task {
            await startRecording(onText: onText)
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
    }

    private func startRecording(onText: @escaping (String) -> Void) async {
        errorMessage = nil

        guard await requestSpeechAuthorization() else {
            errorMessage = "Speech access is denied"
            return
        }

        guard await requestMicrophonePermission() else {
            errorMessage = "Microphone access is denied"
            return
        }

        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer is unavailable"
            return
        }

        stopRecording()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    onText(result.bestTranscription.formattedString)
                    if result.isFinal {
                        self.stopRecording()
                    }
                }
                if let error {
                    self.errorMessage = error.localizedDescription
                    self.stopRecording()
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = error.localizedDescription
            stopRecording()
        }
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            return true
        }
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
