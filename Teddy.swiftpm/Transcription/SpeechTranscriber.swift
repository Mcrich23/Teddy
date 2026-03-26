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

@available(iOS 26.0, *)
private actor SpeechTranscriberBackend {
    var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    var analysisTask: Task<Void, Never>?
    var resultsTask: Task<Void, Never>?
    var analyzer: SpeechAnalyzer?
    var converter: AVAudioConverter?
    var targetAudioFormat: AVAudioFormat?
    var lastBufferTime: CMTime?

    func setContext(_ context: AnalysisContext) async throws {
        try await analyzer?.setContext(context)
    }

    func prepare(
        format: AVAudioFormat,
        transcriber: Speech.SpeechTranscriber,
        onResults: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) async throws {
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        let selectedFormat = await bestAnalyzerFormat(for: transcriber, inputFormat: format)
        configureConversion(from: format, to: selectedFormat)

        try await analyzer.prepareToAnalyze(in: selectedFormat)

        let (inputStream, inputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)
        inputContinuation = inputBuilder

        startResultsTask(with: transcriber, onResults: onResults, onError: onError)
        startAnalysisTask(analyzer: analyzer, inputStream: inputStream, onError: onError)
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        guard let analyzerBuffer = convertIfNeeded(buffer) else { return }

        let startTime = CMTime(value: time.sampleTime, timescale: CMTimeScale(time.sampleRate))
        lastBufferTime = startTime
        inputContinuation?.yield(AnalyzerInput(buffer: analyzerBuffer, bufferStartTime: startTime))
    }

    func finishAudioInput() async {
        inputContinuation?.finish()
        inputContinuation = nil

        let currentAnalyzer = analyzer
        analyzer = nil
        let time = lastBufferTime
        lastBufferTime = nil
        converter = nil
        targetAudioFormat = nil

        // Finalize to get the non-volatile result, or cancel if no audio was received
        if let time {
            try? await currentAnalyzer?.finalizeAndFinish(through: time)
        } else {
            await currentAnalyzer?.cancelAndFinishNow()
        }

        // Wait for tasks to complete naturally after analyzer finishes
        await analysisTask?.value
        analysisTask = nil
        await resultsTask?.value
        resultsTask = nil
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

    private func startResultsTask(
        with transcriber: Speech.SpeechTranscriber,
        onResults: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) {
        resultsTask = Task {
            do {
                for try await result in transcriber.results {
                    guard !Task.isCancelled else { break }
                    onResults(String(result.text.characters))
                }
            } catch {
                guard !Task.isCancelled else { return }
                onError(error)
            }
        }
    }

    private func startAnalysisTask(
        analyzer: SpeechAnalyzer,
        inputStream: AsyncStream<AnalyzerInput>,
        onError: @escaping @Sendable (Error) -> Void
    ) {
        analysisTask = Task {
            do {
                try await analyzer.start(inputSequence: inputStream)
            } catch {
                guard !Task.isCancelled else { return }
                onError(error)
                await self.finishAudioInput()
            }
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
}

@available(iOS 26.0, *)
@Observable
final class SpeechTranscriber: Transcribeable, @unchecked Sendable {
    private(set) var transcript: String = ""

    @ObservationIgnored private let backend = SpeechTranscriberBackend()

    static func isCurrentLocaleDownloaded() async -> Bool {
        guard let locale = await Speech.SpeechTranscriber.supportedLocale(equivalentTo: Locale.current) else {
            return false
        }

        let installedLocales = await Speech.SpeechTranscriber.installedLocales
        return installedLocales.contains { $0.identifier == locale.identifier }
    }

    func resetTranscript() {
        transcript = ""
    }
    
    func setAssistantName(_ name: String) async throws {
        let context = AnalysisContext()
        context.contextualStrings = [.general: [name]]
        
        try await backend.setContext(context)
    }

    // MARK: - Transcribeable Audio Input

    func prepareForAudioInput(format: AVAudioFormat) async throws {
        let transcriber = try await prepareTranscriber()

        try await backend.prepare(
            format: format,
            transcriber: transcriber,
            onResults: { [weak self] result in
                self?.transcript = result
            },
            onError: { [weak self] error in
                self?.setErrorTranscript(error)
            }
        )
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        Task {
            await backend.appendAudioBuffer(buffer, at: time)
        }
    }

    func finishAudioInput() async {
        await backend.finishAudioInput()
    }

    // MARK: - Private Helpers

    private func prepareTranscriber() async throws -> Speech.SpeechTranscriber {
        guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
            throw SpeechTranscriberError.microphonePermissionDenied
        }

        guard let locale = await Speech.SpeechTranscriber.supportedLocale(equivalentTo: Locale.current) else {
            throw SpeechTranscriberError.unsupportedLocale
        }

        let transcriber = Speech.SpeechTranscriber(locale: locale, transcriptionOptions: [], reportingOptions: [.volatileResults, .fastResults], attributeOptions: [])

        if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await installationRequest.downloadAndInstall()
        }

        return transcriber
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
