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
    private var session: LanguageModelSession
    private let camera: CameraModel
    private let toolUIManager: ToolEnabledUIManager
    
    init(camera: CameraModel, toolUIManager: ToolEnabledUIManager) {
        self.camera = camera
        self.toolUIManager = toolUIManager
        self.session = LanguageModelSession(tools: Self.getTools(camera: camera, toolUIManager: toolUIManager), instructions: llmInstructions)
    }
    
    var isResponding: Bool { session.isResponding }
    
    var respondTask: Task<Void, Never>?
    var respondingPrompt: String?
    
    func getCommand(from transcript: String?) -> String? {
        var transcript = transcript
        // Allow different alts since Rovo isn't a word.
        let rovoAlts = [
            "Rovo",
        ]
        
        for alt in rovoAlts {
            transcript = transcript?.replacingOccurrences(of: alt, with: "(rovo)\(alt)").replacingOccurrences(of: alt.lowercased(), with: "(rovo)\(alt.lowercased())")
        }
        
        return transcript?.components(separatedBy: "(rovo)").dropFirst().joined(separator: "(rovo)").replacingOccurrences(of: "(rovo)", with: "")
    }

    func pendModelResponse(from boundValue: Binding<String>) async -> Bool {
        let transcript = boundValue.wrappedValue
        try? await Task.sleep(for: .milliseconds(1500))
        guard transcript == boundValue.wrappedValue, !transcript.isEmpty, let command = getCommand(from: transcript), command != getCommand(from: respondingPrompt) else {
            return false
        }
        
        if command.isEmpty {
            return true
        }
        
        respondTask?.cancel()
        
        // Restart session is requested instead of passing to LLM
        if command.lowercased().contains("restart llm session") {
            restartSession()
            return true
        }
        
        respondTask = Task {
            respondingPrompt = command
            
            do {
                try await streamModelResponse(from: command)
            } catch {
                print(error)
            }
        }
        return true
    }
    
    func streamModelResponse(from transcript: String) async throws {
        guard !isResponding else { throw FMErrors.modelBusy }
        let stream = session.streamResponse(to: transcript)
        
        for try await chunk in stream where chunk.content != "null" {
            modelResponse = try? AttributedString(styledMarkdown: chunk.content)
        }
    }
    
    // MARK: – Tool Stuff
    func restartSession() {
        self.session = LanguageModelSession(tools: Self.getTools(camera: camera, toolUIManager: toolUIManager), instructions: llmInstructions)
        self.modelResponse = AttributedString("Session Restarted.")
    }
    
    /// Generates an array of tools to use.
    private static func getTools(camera: CameraModel, toolUIManager: ToolEnabledUIManager) -> [any Tool] {
        [
            TakePhotoTool(camera: camera, uiManager: toolUIManager),
            StartVideoTool(camera: camera, uiManager: toolUIManager),
            StopVideoTool(camera: camera, uiManager: toolUIManager),
            SwitchCameraTool(camera: camera, uiManager: toolUIManager),
            GetAvailableCamerasTool(camera: camera, uiManager: toolUIManager),
            SetCaptureModeTool(camera: camera, uiManager: toolUIManager),
            SetFlashModeTool(camera: camera, uiManager: toolUIManager),
            SetLiveTool(camera: camera, uiManager: toolUIManager),
            GetZoomFactorsTool(camera: camera, uiManager: toolUIManager),
            GetZoomTool(camera: camera, uiManager: toolUIManager),
            SetZoomTool(camera: camera, uiManager: toolUIManager),
        ]
    }
}

private let llmInstructions: String = "You are Project Rovo, a helpful camera app designed to help people with fine motor issues use a camera. Please note that all input you receive has been translated from voice to text. DO NOT CAPTURE UNLESS DIRECTED BY THE USER. When asked to take a selfie, please ensure that you are using the selfie camera before taking the picture."

@Observable
@MainActor
final class ToolEnabledUIManager {
    /// The rotation of the ``SwitchCameraButton`` label.
    private(set) var cameraFlipRotation: CGFloat = 0
    
    /// Updates ``cameraFlipRotation``
    func flipCamera() {
        cameraFlipRotation += 180
    }
    
    /// The current tool being used
    private(set) var currentTool: String?
    
    func setCurrentTool(_ tool: String?) {
        currentTool = tool
    }
}

enum FMErrors: Error {
    case noResponse
    case modelBusy
}
