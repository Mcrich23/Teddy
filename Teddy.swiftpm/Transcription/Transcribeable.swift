//
//  Transcribeable.swift
//  Teddy
//
//  Created by Morris Richman on 2/23/26.
//

import Foundation
import AVFoundation

protocol Transcribeable {
    var transcript: String { get }
    
    /// Called once before audio streaming begins so the conformer can set up
    /// its recognition request / analyzer with the correct audio format.
    func prepareForAudioInput(format: AVAudioFormat) async throws
    
    /// Called by `Transcriber` each time a new audio buffer is captured.
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime)
    
    /// Called when the audio stream ends so the conformer can finalize.
    func finishAudioInput() async
    
    func resetTranscript() throws
}

@Observable
final class Transcriber: @unchecked Sendable {
    var speechRecognizer: Transcribeable?
    var inputNoiseLevel: CGFloat = 0.0
    
    @ObservationIgnored private var audioEngine: AVAudioEngine?
    
    func configure() async {
        // Use `SpeechTranscriber` if possible
        if #available(iOS 26, *) {
            if await SpeechTranscriber.isCurrentLocaleDownloaded() {
                speechRecognizer = SpeechTranscriber()
                return
            }
        }
        
        let speechRecognizer = SpeechRecognizer()
        await speechRecognizer.configure()
        
        self.speechRecognizer = speechRecognizer
    }
    
    var transcript: String {
        speechRecognizer?.transcript ?? ""
    }
    
    func startTranscribing() async throws {
        guard let speechRecognizer else {
            throw TranscriberError.noSpeechRecognizer
        }
        
        do {
            try await startAudioEngine(for: speechRecognizer)
        } catch {
            await stopTranscribing()
        }
    }
    
    func stopTranscribing() async {
        stopAudioEngine()
        await speechRecognizer?.finishAudioInput()
        inputNoiseLevel = 0
    }
    
    /// Clears the transcript
    /// - Returns:
    /// The final version of the existing transcript
    func resetTranscript() async throws -> String {
        guard let speechRecognizer else {
            throw TranscriberError.noSpeechRecognizer
        }
        
        await speechRecognizer.finishAudioInput()
        let transcript = speechRecognizer.transcript
        try speechRecognizer.resetTranscript()
        
        return transcript
    }
    
    // MARK: - Audio Engine
    
    private func startAudioEngine(for recognizer: Transcribeable) async throws {
        let engine = AVAudioEngine()
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        
#if targetEnvironment(macCatalyst)
        try audioSession.setCategory(.playAndRecord, options: [.duckOthers, .allowBluetoothA2DP, .allowBluetoothHFP])
#else
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.duckOthers, .allowBluetoothA2DP, .bluetoothHighQualityRecording, .allowBluetoothHFP])
#endif
        
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        try await recognizer.prepareForAudioInput(format: recordingFormat)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            guard let self else { return }
            recognizer.appendAudioBuffer(buffer, at: when)
            self.updateNoiseLevel(from: buffer)
        }
        
        engine.prepare()
        try engine.start()
        
        self.audioEngine = engine
    }
    
    private func stopAudioEngine() {
        guard audioEngine != nil else { return }
        
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
    }
    
    private func updateNoiseLevel(from buffer: AVAudioPCMBuffer) {
        let volume = getVolume(from: buffer, bufferSize: 1024)
        inputNoiseLevel = CGFloat(volume)
    }
    
    private func getVolume(from buffer: AVAudioPCMBuffer, bufferSize: Int) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else {
            return 0
        }

        let channelDataArray = Array(UnsafeBufferPointer(start:channelData, count: bufferSize))

        var outEnvelope = [Float]()
        var envelopeState:Float = 0
        let envConstantAtk:Float = 0.16
        let envConstantDec:Float = 0.003

        for sample in channelDataArray {
            let rectified = abs(sample)

            if envelopeState < rectified {
                envelopeState += envConstantAtk * (rectified - envelopeState)
            } else {
                envelopeState += envConstantDec * (rectified - envelopeState)
            }
            outEnvelope.append(envelopeState)
        }

        // 0.007 is the low pass filter to prevent
        // getting the noise entering from the microphone
        if let maxVolume = outEnvelope.max(),
            maxVolume > Float(0.015) {
            return maxVolume
        } else {
            return 0.0
        }
    }
}

enum TranscriberError: Error {
    case noSpeechRecognizer
}
