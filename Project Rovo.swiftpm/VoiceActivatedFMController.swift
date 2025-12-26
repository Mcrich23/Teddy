//
//  VoiceActivatedFMController.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/21/25.
//

import Foundation
import FoundationModels
import SwiftUI

@Observable
@MainActor
final class VoiceActivatedFMController {
    var modelResponse: AttributedString?
    private let session = LanguageModelSession()
    
    var isResponding: Bool { session.isResponding }
    
    var respondTask: Task<Void, Never>?
    var respondingPrompt: String?

    func pendModelResponse(from boundValue: Binding<String>) async -> Bool {
        let transcript = boundValue.wrappedValue
        try? await Task.sleep(for: .milliseconds(1500))
        guard transcript == boundValue.wrappedValue, !transcript.isEmpty, transcript != respondingPrompt else {
            return false
        }
        
        respondTask?.cancel()
        respondTask = Task {
            respondingPrompt = transcript
            
            do {
                try await streamModelResponse(from: transcript)
            } catch {
                print(error)
            }
        }
        return true
    }
    
    func streamModelResponse(from transcript: String) async throws {
        guard !isResponding else { throw FMErrors.modelBusy }
        let stream = session.streamResponse(to: transcript)
        
        for try await chunk in stream {
            modelResponse = try? AttributedString(styledMarkdown: chunk.content)
        }
    }
}

enum FMErrors: Error {
    case noResponse
    case modelBusy
}
