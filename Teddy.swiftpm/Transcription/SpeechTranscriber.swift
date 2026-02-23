//
//  SpeechTranscriber.swift
//  Teddy
//
//  Created by Morris Richman on 2/23/26.
//

import Foundation
import Speech

@MainActor
@Observable
final class SpeechTranscriber: Transcribeable {
    private(set) var transcript: String = ""

    func startTranscribing() {
    }

    func stopTranscribing() {
    }

    func resetTranscript() {
    }
}
