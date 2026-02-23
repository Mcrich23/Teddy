//
//  Transcribeable.swift
//  Teddy
//
//  Created by Morris Richman on 2/23/26.
//

import Foundation

@MainActor
protocol Transcribeable {
    var transcript: String { get }
    func startTranscribing() throws
    func stopTranscribing() throws
    func resetTranscript() throws
}

@Observable
final class Transcriber: Transcribeable {
    var speechRecognizer: Transcribeable?
    
    func configure() async {
        // Use `SpeechTranscriber` if possible
        if #available(iOS 26, *) {
            if await SpeechTranscriber.isCurrentLocaleDownloaded() {
                speechRecognizer = SpeechTranscriber()
                return
            }
        }
        
        speechRecognizer = SpeechRecognizer()
    }
    
    var transcript: String {
        speechRecognizer?.transcript ?? ""
    }
    
    func startTranscribing() throws {
        guard let speechRecognizer else {
            throw TranscriberError.noSpeechRecognizer
        }
        
        try speechRecognizer.startTranscribing()
    }
    
    func stopTranscribing() throws {
        guard let speechRecognizer else {
            throw TranscriberError.noSpeechRecognizer
        }
        
        try speechRecognizer.stopTranscribing()
    }
    
    func resetTranscript() throws {
        guard let speechRecognizer else {
            throw TranscriberError.noSpeechRecognizer
        }
        
        try speechRecognizer.resetTranscript()
    }
}

enum TranscriberError: Error {
    case noSpeechRecognizer
}
