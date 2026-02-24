//
//  SpeechRecognizer.swift
//  Anchor
//
//  Created by Morris Richman on 1/20/25.
//

import Foundation
import AVFoundation
import Speech
import SwiftUI

/// A helper for transcribing speech to text using SFSpeechRecognizer and AVAudioEngine.
@Observable
final class SpeechRecognizer: Transcribeable {
    enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    
    private(set) var transcript: String = ""
    
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private let recognizer: SFSpeechRecognizer?
    
    /**
     Initializes a new speech recognizer. If this is the first time you've used the class, it
     requests access to the speech recognizer and the microphone.
     */
    init() {
        recognizer = SFSpeechRecognizer()
        guard recognizer != nil else {
            transcribe(RecognizerError.nilRecognizer)
            return
        }
    }
    
    func configure() async {
        do {
            guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                throw RecognizerError.notAuthorizedToRecognize
            }
            guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                throw RecognizerError.notPermittedToRecord
            }
        } catch {
            transcribe(error)
        }
    }
    
    func resetTranscript() {
        transcript = ""
    }
    
    // MARK: - Transcribeable Audio Input
    
    func prepareForAudioInput(format: AVAudioFormat) throws {
        guard let recognizer, recognizer.isAvailable else {
            throw RecognizerError.recognizerIsUnavailable
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.contextualStrings = ["Teddy"]
        self.request = request
        
        self.task = recognizer.recognitionTask(with: request, resultHandler: { [weak self] result, error in
            self?.recognitionHandler(result: result, error: error)
        })
    }
    
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        request?.append(buffer)
    }
    
    func finishAudioInput() {
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }
    
    // MARK: - Recognition Handling
    
    private func recognitionHandler(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            transcribe(result.bestTranscription.formattedString)
        }
    }
    
    private func transcribe(_ message: String) {
        transcript = message
    }
    
    private func transcribe(_ error: Error) {
        var errorMessage = ""
        if let error = error as? RecognizerError {
            errorMessage += error.message
        } else {
            errorMessage += error.localizedDescription
        }
        transcript = "<< \(errorMessage) >>"
    }
}


extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}


extension AVAudioSession {
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
}

extension AVAudioPCMBuffer: @retroactive @unchecked Sendable {
    
}
