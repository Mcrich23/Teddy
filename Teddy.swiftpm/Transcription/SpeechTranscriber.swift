//
//  SpeechTranscriber.swift
//  Teddy
//
//  Created by Morris Richman on 2/23/26.
//

import Foundation
import AVFoundation
import CoreMedia
import Speech

@MainActor
@Observable
final class SpeechTranscriber: Transcribeable {
    private let tapBufferSize: AVAudioFrameCount = 1024

    private(set) var transcript: String = ""

    @ObservationIgnored private var audioEngine: AVAudioEngine?
    @ObservationIgnored private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    @ObservationIgnored private var analysisTask: Task<Void, Never>?
    @ObservationIgnored private var resultsTask: Task<Void, Never>?
    @ObservationIgnored private var analyzer: SpeechAnalyzer?
    @ObservationIgnored private var converter: AVAudioConverter?
    @ObservationIgnored private var targetAudioFormat: AVAudioFormat?
    @ObservationIgnored private var isTranscribing = false

    func startTranscribing() {
        guard !isTranscribing else { return }
        isTranscribing = true

        Task {
            await startStreamingTranscription()
        }
    }

    func stopTranscribing() {
        guard isTranscribing else { return }
        isTranscribing = false

        let currentAnalyzer = teardownTranscriptionResources()
        Task {
            await currentAnalyzer?.cancelAndFinishNow()
        }
    }

    func resetTranscript() {
        transcript = ""
    }

    private func startStreamingTranscription() async {
        do {
            let transcriber = try await prepareTranscriber()
            guard isTranscribing else { return }

            try configureAudioSession()

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)

            let analyzer = SpeechAnalyzer(modules: [transcriber])
            self.analyzer = analyzer

            let selectedFormat = await bestAnalyzerFormat(for: transcriber, inputFormat: inputFormat)
            configureConversion(from: inputFormat, to: selectedFormat)

            try await analyzer.prepareToAnalyze(in: selectedFormat)

            let (inputStream, inputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)
            inputContinuation = inputBuilder
            audioEngine = engine

            startResultsTask(with: transcriber)
            startAnalysisTask(analyzer: analyzer, inputStream: inputStream)
            installInputTap(on: inputNode, format: inputFormat)

            engine.prepare()
            try engine.start()
        } catch {
            setErrorTranscript(error)
            stopTranscribing()
        }
    }

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
#if targetEnvironment(macCatalyst)
        try audioSession.setCategory(.playAndRecord, options: [.duckOthers, .allowBluetoothA2DP, .allowBluetoothHFP])
#else
        try audioSession.setCategory(.playAndRecord, options: [.duckOthers, .allowBluetoothA2DP, .bluetoothHighQualityRecording, .allowBluetoothHFP])
#endif
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func teardownTranscriptionResources() -> SpeechAnalyzer? {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        inputContinuation?.finish()
        inputContinuation = nil

        analysisTask?.cancel()
        analysisTask = nil

        resultsTask?.cancel()
        resultsTask = nil

        let currentAnalyzer = analyzer
        analyzer = nil

        converter = nil
        targetAudioFormat = nil

        return currentAnalyzer
    }

    private func prepareTranscriber() async throws -> Speech.SpeechTranscriber {
        guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
            throw SpeechTranscriberError.microphonePermissionDenied
        }

        guard let locale = await Speech.SpeechTranscriber.supportedLocale(equivalentTo: Locale.current) else {
            throw SpeechTranscriberError.unsupportedLocale
        }

        let transcriber = Speech.SpeechTranscriber(locale: locale, preset: .progressiveTranscription)

        if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await installationRequest.downloadAndInstall()
        }

        return transcriber
    }

    private func bestAnalyzerFormat(
        for transcriber: Speech.SpeechTranscriber,
        inputFormat: AVAudioFormat
    ) async -> AVAudioFormat {
        await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber],
            considering: inputFormat
        ) ?? inputFormat
    }

    private func configureConversion(from inputFormat: AVAudioFormat, to selectedFormat: AVAudioFormat) {
        targetAudioFormat = selectedFormat
        converter = selectedFormat != inputFormat
            ? AVAudioConverter(from: inputFormat, to: selectedFormat)
            : nil
    }

    private func startResultsTask(with transcriber: Speech.SpeechTranscriber) {
        resultsTask = Task {
            do {
                for try await result in transcriber.results {
                    guard !Task.isCancelled else { break }
                    transcript = String(result.text.characters)
                }
            } catch {
                guard !Task.isCancelled else { return }
                setErrorTranscript(error)
            }
        }
    }

    private func startAnalysisTask(
        analyzer: SpeechAnalyzer,
        inputStream: AsyncStream<AnalyzerInput>
    ) {
        analysisTask = Task { [weak self] in
            do {
                try await analyzer.start(inputSequence: inputStream)
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.setErrorTranscript(error)
                    self?.stopTranscribing()
                }
            }
        }
    }

    private func installInputTap(on inputNode: AVAudioInputNode, format inputFormat: AVAudioFormat) {
        inputNode.installTap(onBus: 0, bufferSize: tapBufferSize, format: inputFormat) { [weak self] buffer, when in
            guard let self, self.isTranscribing else { return }
            guard let analyzerBuffer = self.convertIfNeeded(buffer) else { return }

            let startTime = CMTime(value: when.sampleTime, timescale: CMTimeScale(when.sampleRate))
            self.inputContinuation?.yield(AnalyzerInput(buffer: analyzerBuffer, bufferStartTime: startTime))
        }
    }

    private func convertIfNeeded(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let targetAudioFormat else {
            return buffer
        }

        guard buffer.format != targetAudioFormat else {
            return buffer
        }

        guard let converter else {
            return nil
        }

        let ratio = targetAudioFormat.sampleRate / buffer.format.sampleRate
        let outputCapacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up))

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetAudioFormat,
            frameCapacity: max(outputCapacity, 1)
        ) else {
            return nil
        }

        var error: NSError?
        let provider = OneShotBufferProvider(buffer: buffer)
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if let nextBuffer = provider.takeBuffer() {
                outStatus.pointee = .haveData
                return nextBuffer
            }

            outStatus.pointee = .noDataNow
            return nil
        }

        switch status {
        case .haveData, .inputRanDry, .endOfStream:
            return outputBuffer.frameLength > 0 ? outputBuffer : nil
        case .error:
            return nil
        @unknown default:
            return nil
        }
    }

    private func setErrorTranscript(_ error: Error) {
        if let transcriberError = error as? SpeechTranscriberError {
            transcript = "<< \(transcriberError.message) >>"
            return
        }

        transcript = "<< \(error.localizedDescription) >>"
    }
}

private final class OneShotBufferProvider: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer: AVAudioPCMBuffer?

    init(buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }

    func takeBuffer() -> AVAudioPCMBuffer? {
        lock.lock()
        defer { lock.unlock() }

        defer { buffer = nil }
        return buffer
    }
}

private enum SpeechTranscriberError: Error {
    case microphonePermissionDenied
    case unsupportedLocale

    var message: String {
        switch self {
        case .microphonePermissionDenied:
            return "Not permitted to record audio"
        case .unsupportedLocale:
            return "Speech transcription is unavailable for this locale"
        }
    }
}
