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
final class VoiceActivatedFMController<CameraModel: Camera> {
    var modelResponse: AttributedString?
    private let session: LanguageModelSession
    
    init(camera: CameraModel, toolUIManager: ToolEnabledUIManager) {
        self.session = LanguageModelSession(tools: Self.getTools(camera: camera, toolUIManager: toolUIManager), instructions: "You are Project Rovo, a helpful camera app designed to help people with fine motor issues use a camera. Please note that all input you receive has been translated from voice to text. DO NOT CAPTURE UNLESS DIRECTED BY THE USER.")
    }
    
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
    
    // MARK: – Tool Stuff
    /// Generates an array of tools to use.
    private static func getTools(camera: CameraModel, toolUIManager: ToolEnabledUIManager) -> [any Tool] {
        [
            CaptureTool(camera: camera),
            SwitchCameraTool(camera: camera, uiManager: toolUIManager),
            GetAvailableCamerasTool(camera: camera),
            SetCaptureModeTool(camera: camera),
            SetFlashModeTool(camera: camera)
        ]
    }
}

@Observable
@MainActor
final class ToolEnabledUIManager {
    /// The rotation of the ``SwitchCameraButton`` label.
    private(set) var cameraFlipRotation: CGFloat = 0
    
    /// Updates ``cameraFlipRotation``
    func flipCamera() {
        cameraFlipRotation += 180
    }
}

enum FMErrors: Error {
    case noResponse
    case modelBusy
}
