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
        guard !toolUIManager.isActiveListening else { return transcript }
        
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
            SetHDRTool(camera: camera, uiManager: toolUIManager),
            GetZoomFactorsTool(camera: camera, uiManager: toolUIManager),
            GetZoomTool(camera: camera, uiManager: toolUIManager),
            SetZoomTool(camera: camera, uiManager: toolUIManager),
            SetActiveListeningTool(camera: camera, uiManager: toolUIManager),
        ]
    }
}

private let llmInstructions: String = "You are Project Rovo, a helpful camera app designed to help people with fine motor issues use a camera. Please note that all input you receive has been translated from voice to text. When asked to take a selfie, please ensure that you are using the front facing selfie camera before taking the picture. Generally, the front camera is the selfie camera. To zoom all of the way out, zoom to 0. To zoom all the way in, zoom to 1000. These zoom parameters will be overriden by the boundaries. Only present what the zoom ended up being, never what you attempted to zoom. DO NOT CAPTURE UNLESS DIRECTED BY THE USER."

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
    
    /// Tracks if Rovo is actively listening (wake word not needed)
    private(set) var isActiveListening = false
    
    func setActiveListening(_ isActive: Bool) {
        isActiveListening = isActive
    }
}

enum FMErrors: Error {
    case noResponse
    case modelBusy
}

extension AttributedString {
    init(styledMarkdown markdownString: String) throws {
        let newLine = AttributedString("\n")
        let markdownString = markdownString
            .replacingOccurrences(of: "\n\n", with: "\u{2029}\u{2029}\n\n")
        
        var output = try AttributedString(
            markdown: markdownString,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            ),
            baseURL: nil
        )
        
        while let range = output.range(of: "\u{2029}\u{2029}") {
            output[range] = newLine[newLine.startIndex..<newLine.endIndex]
        }

        for (intentBlock, intentRange) in output.runs[AttributeScopes.FoundationAttributes.PresentationIntentAttribute.self].reversed() {
            guard let intentBlock = intentBlock else { continue }
            for intent in intentBlock.components {
                switch intent.kind {
                case .header(level: let level):
                    switch level {
                    case 1:
                        output[intentRange].font = .system(.title).bold()
                    case 2:
                        output[intentRange].font = .system(.title2).bold()
                    case 3:
                        output[intentRange].font = .system(.title3).bold()
                    default:
                        break
                    }
                default:
                    break
                }
            }
            
            if intentRange.lowerBound != output.startIndex {
                output.characters.insert(contentsOf: "\n", at: intentRange.lowerBound)
            }
        }

        self = output
    }
}
