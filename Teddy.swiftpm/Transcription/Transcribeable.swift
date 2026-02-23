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
    func startTranscribing()
    func stopTranscribing()
    func resetTranscript()
}

@Observable
final class Transcriber: Transcribeable {
    let speechRecognizer = SpeechRecognizer()
    
    var transcript: String {
        speechRecognizer.transcript
    }
    
    func startTranscribing() {
        speechRecognizer.startTranscribing()
    }
    
    func stopTranscribing() {
        speechRecognizer.stopTranscribing()
    }
    
    func resetTranscript() {
        speechRecognizer.resetTranscript()
    }
}
