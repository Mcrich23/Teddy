//
//  Transcribable.swift
//  Teddy
//
//  Created by Morris Richman on 2/23/26.
//

import Foundation

@MainActor
protocol Transcribable {
    var transcript: String { get }
    func startTranscribing()
    func stopTranscribing()
    func resetTranscript()
}

@Observable
final class Transcriber: Transcribable {
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
