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
    
    private var responseCount: Int = 0
    
    func getCommand(from transcript: String?) -> String? {
        guard !toolUIManager.isActiveListening || camera.captureActivity.isRecording else { return transcript }
        
        var transcript = transcript
        // Allow different alts since Rovo isn't a word.
        let rovoAlts = [
            "Rovo",
            "Robo",
            "Bravo",
            "Rubber",
            "Bro",
            "Brother",
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
        if command.lowercased().contains("restart llm session") || command.lowercased().contains("restart model") || command.lowercased().contains("clear context") {
            restartSession()
            return true
        }
        
        // Auto restart session to fix context issues
        if responseCount >= 3 {
            restartSession(showAlert: false)
            responseCount = 0
        }
        
        respondTask = Task {
            respondingPrompt = command
            responseCount += 1
            
            do {
                try await streamModelResponse(from: command)
            } catch {
                print(error)
            }
        }
        return true
    }
    
    private func generatePrompt(command: String) -> String {
        """
        \(command)
            
        Here is the current state of the app. DO NOT SHARE THIS WITH THE USER:
        
        Current Zoom: \(camera.currentZoom)
        Current Camera: \(camera.cameraPosition.rawValue)
        Other Cameras: \(camera.availableCameras.keys.filter({ $0 != camera.cameraPosition }).map({ $0.rawValue }))
        Flash Mode: \(camera.flashMode.rawValue)
        HDR Enabled: \(camera.isHDRVideoEnabled)
        Live Photo Enabled: \(camera.isLivePhotoEnabled)
        """
    }
    
    func streamModelResponse(from transcript: String) async throws {
        guard !isResponding else { throw FMErrors.modelBusy }
        let stream = session.streamResponse(to: transcript)
        
        for try await chunk in stream where chunk.content != "null" {
            modelResponse = try? AttributedString(styledMarkdown: chunk.content)
        }
    }
    
    // MARK: – Tool Stuff
    func restartSession(showAlert: Bool = true) {
        self.session = LanguageModelSession(tools: Self.getTools(camera: camera, toolUIManager: toolUIManager), instructions: llmInstructions)
        if showAlert {
            self.modelResponse = AttributedString("Session Restarted.")
        }
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
            DismissOnboardingTool(uiManager: toolUIManager)
        ]
    }
}

private let llmInstructions: String = "You are Project Rovo, a helpful camera app designed to help people with fine motor issues use a camera. Please note that all input you receive has been translated from voice to text. When asked to take a selfie, please ensure that you are using the front facing selfie camera before capturing the media. When zooming, only present what the zoom ended up being, never what you attempted to zoom. DO NOT CAPTURE UNLESS DIRECTED BY THE USER. If a user asks to take a selfie, capture a photo as your last action."

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
    
    /// Tracks if the user has onboarded
    private(set) var isOnboarding: Bool = false
    
    func setOnboarding(_ isOnboarding: Bool) {
        self.isOnboarding = isOnboarding
    }
    
    /// Triggers the countdown animation. The animation is 5 seconds long.
    private(set) var countdownTrigger: Bool = false
    
    func triggerCountdown() {
        countdownTrigger.toggle()
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
