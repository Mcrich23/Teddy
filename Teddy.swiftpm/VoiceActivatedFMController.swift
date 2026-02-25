//
//  VoiceActivatedFMController.swift
//  Teddy
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
    private let sounds = Sounds()
    
    /// The next transcript input does not require a wake word if this is set to true
    private(set) var isTemporarilyActiveListening: Bool = false
    
    func stopTemporaryListening() {
        guard isTemporarilyActiveListening else { return }
        isTemporarilyActiveListening = false
        Task {
            try? await sounds.playCancelSound()
        }
    }
    
    init(camera: CameraModel, toolUIManager: ToolEnabledUIManager, willOnboard: Bool) {
        self.camera = camera
        self.toolUIManager = toolUIManager
        
        // Only provide onboarding tools when onboarding
        if willOnboard {
            self.session = LanguageModelSession(tools: [DismissOnboardingTool(uiManager: toolUIManager)], instructions: llmInstructions)
        } else {
            self.session = LanguageModelSession(tools: Self.getTools(camera: camera, toolUIManager: toolUIManager), instructions: llmInstructions)
        }
        self.lastStartDate = .now
    }
    
    var isResponding: Bool { session.isResponding }
    private var lastStartDate: Date
    
    var respondTask: Task<Void, Never>?
    var respondingPrompt: String?
    
    private var responseCount: Int = 0
    
    // Allow different alts since Teddy isn't a word.
    private var teddyAlts: [String] {
        guard toolUIManager.assistantName.lowercased() == "teddy" else {
            return [toolUIManager.assistantName]
        }
        
        return ["Teddy", "Ted", "Betty"]
    }
    
    func getCommand(from transcript: String?) -> String? {
        guard (!toolUIManager.isActiveListening && !isTemporarilyActiveListening) || camera.captureActivity.isRecording else {
            return transcript?.trimmingCharacters(in: .punctuationCharacters)
        }
        
        var transcript = transcript
        
        for alt in teddyAlts {
            transcript = transcript?.replacingOccurrences(of: alt, with: "(teddy)\(alt)").replacingOccurrences(of: alt.lowercased(), with: "(teddy)\(alt.lowercased())")
        }
        
        return transcript?.components(separatedBy: "(teddy)").dropFirst().joined(separator: "(teddy)").replacingOccurrences(of: "(teddy)", with: "").trimmingCharacters(in: .punctuationCharacters)
    }

    /// - Returns:
    /// `true` if the transcription should be reset.
    @discardableResult
    func pendModelResponse(with transcriber: Transcriber) async -> Bool {
        let pendDate = Date()
        var transcript = transcriber.transcript
        
        // Wait for input level to be minimal suggesting input has stopped
        let audioTimer = Task {
            var inputNoiseLevel = transcriber.inputNoiseLevel
            for _ in 0..<20 {
                inputNoiseLevel = transcriber.inputNoiseLevel
                try? await Task.sleep(for: .milliseconds(100))
                
                guard !Task.isCancelled else {
                    return true
                }
                
                if inputNoiseLevel > 0.35 {
                    return false
                }
            }
            guard !Task.isCancelled else {
                return true
            }
            
            transcript = (try? await transcriber.resetTranscript()) ?? transcript
            return true
        }
        
        // Race on transcript finishing suggesting the person has stopped talking
        let transcriptTimer = Task {
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else {
                return true
            }
            
            guard transcript == transcriber.transcript, !transcript.isEmpty, let finalTranscript = try? await transcriber.resetTranscript() else {
                return false
            }
            
            guard !Task.isCancelled else {
                return true
            }
            
            transcript = finalTranscript
            return false
        }
        
        let transcriptAllowsCompletion = await transcriptTimer.value
        
        if transcriptAllowsCompletion {
            audioTimer.cancel()
        }
        
        let audioAllowsCompletion = await audioTimer.value
        
        guard transcriptAllowsCompletion || audioAllowsCompletion else {
            return false
        }
        
        // Ensure that model was not restarted between pend time and now
        guard lastStartDate < pendDate else {
            return false
        }
        
        if transcript.replacingOccurrences(of: teddyAlts, with: "").trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .punctuationCharacters).isEmpty && !transcript.trimmingCharacters(in: .punctuationCharacters).isEmpty {
            isTemporarilyActiveListening = true
            try? await sounds.playStartListeningSound()
            return true
        }
                
        guard let command = getCommand(from: transcript), command != getCommand(from: respondingPrompt) else {
            let latterTranscript = transcript
            try? await Task.sleep(for: .milliseconds(1500))
            if latterTranscript == transcript, !latterTranscript.isEmpty {
                return true
            }
            return false
        }
        
        guard !command.isEmpty else {
            return true
        }
        
        respondTask?.cancel()
        
        isTemporarilyActiveListening = false
        
        // Restart session is requested instead of passing to LLM
        if command.lowercased().contains("restart llm session") || command.lowercased().contains("restart model") || command.lowercased().contains("clear context") {
            restartSession()
            try? await sounds.playFinishActionSound()
            return true
        }
        
        // Handle Hardcoded Commands
        let didHandleWithHardcodedCommand = (try? await useHardCodedTasksIfPossible(command: command)) ?? false
        if didHandleWithHardcodedCommand {
            try? await sounds.playFinishActionSound()
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
                guard !Task.isCancelled else { return }
                
                try? await sounds.playFinishActionSound()
            } catch {
                guard !Task.isCancelled else { return }
                print(error)
                try? await sounds.playErrorSound()
            }
        }
        
        // Wait to return function until task is complete
        _ = await respondTask?.result
        
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
        guard !Task.isCancelled else { return }
        let stream = session.streamResponse(to: transcript)
        
        for try await chunk in stream where chunk.content != "null" {
            guard !Task.isCancelled else { return }
            
            modelResponse = try? AttributedString(styledMarkdown: chunk.content)
        }
    }
    
    // MARK: – Tool Stuff
    func restartSession(showAlert: Bool = true) {
        respondTask?.cancel()
        
        self.session = LanguageModelSession(tools: Self.getTools(camera: camera, toolUIManager: toolUIManager), instructions: llmInstructions)
        if showAlert {
            self.modelResponse = AttributedString("Session Restarted.")
        }
        self.lastStartDate = .now
    }
    
    /// Generates an array of tools to use.
    private static func getTools(camera: CameraModel, toolUIManager: ToolEnabledUIManager) -> [any Tool] {
        [
            TakePhotoTool(camera: camera, uiManager: toolUIManager),
            StartVideoTool(camera: camera, uiManager: toolUIManager),
            StopVideoTool(camera: camera, uiManager: toolUIManager),
            SwitchCameraTool(camera: camera, uiManager: toolUIManager),
            SetCaptureModeTool(camera: camera, uiManager: toolUIManager),
            SetFlashModeTool(camera: camera, uiManager: toolUIManager),
            SetLiveTool(camera: camera, uiManager: toolUIManager),
            SetHDRTool(camera: camera, uiManager: toolUIManager),
            SetZoomTool(camera: camera, uiManager: toolUIManager),
            SetActiveListeningTool(camera: camera, uiManager: toolUIManager),
            SetAssistantName(uiManager: toolUIManager)
//            GetAvailableCamerasTool(camera: camera, uiManager: toolUIManager),
//            GetZoomFactorsTool(camera: camera, uiManager: toolUIManager),
//            GetZoomTool(camera: camera, uiManager: toolUIManager),
        ]
    }
    
    // MARK: Hard Coded Tasks
    /// Acts with a hardcoded function for faster response if the command matches
    ///  - Parameter command: The full command for the device.
    ///  - Returns:
    ///  `true` if a hardcoded task was used. Otherwise, it returns `false`.
    private func useHardCodedTasksIfPossible(command: String) async throws -> Bool {
        // Remove wake words and whitespace from command.
        let command = command.lowercased().replacingOccurrences(of: teddyAlts.map({ $0.lowercased() }), with: "").trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .punctuationCharacters)
        
        if command.hasSuffix("flip camera") || command.hasSuffix("switch camera") || command.hasSuffix("change camera") || command.hasSuffix("toggle camera") || command.hasSuffix("flip the camera") || command.hasSuffix("switch the camera") || command.hasSuffix("change the camera") || command.hasSuffix("toggle the camera") {
            try await flipCamera()
            return true
        }
        
        if command.hasSuffix("take a selfie") || command.hasSuffix("snap a selfie") {
            try await takeSelfie()
            return true
        }
        
        if command.hasSuffix("take a photo") || command.hasSuffix("take a picture") || command.hasSuffix("snap a photo") || command.hasSuffix("snap a picture") {
            try await takePhoto()
            return true
        }
        
        if command.hasSuffix("take a video") || command.hasSuffix("start recording") || command.hasSuffix("start a video") || command.hasSuffix("start the video") {
            try await startRecordingVideo()
            return true
        }
        
        if command.hasSuffix("stop recording") || command.hasSuffix("stop video") || command.hasSuffix("stop the video") || command.hasSuffix("end recording") || command.hasSuffix("end the video") {
            try await stopRecordingVideo()
            return true
        }
        
        return false
    }
    
    private func flipCamera() async throws {
        let switchCamera = SwitchCameraTool(camera: camera, uiManager: toolUIManager)
        _ = try await switchCamera.call(arguments: .init(cameraPosition: nil))
    }
    
    private func takeSelfie() async throws {
        if camera.cameraPosition != .front {
            let switchCamera = SwitchCameraTool(camera: camera, uiManager: toolUIManager)
            _ = try await switchCamera.call(arguments: .init(cameraPosition: .front))
        }
        try await takePhoto()
    }
    
    private func takePhoto() async throws {
        if camera.captureMode != .photo {
            let setCameraMode = SetCaptureModeTool(camera: camera, uiManager: toolUIManager)
            _ = try await setCameraMode.call(arguments: .init(mode: .photo))
        }
        
        let takePhoto = TakePhotoTool(camera: camera, uiManager: toolUIManager)
        _ = try await takePhoto.call(arguments: .init())
    }
    
    private func startRecordingVideo() async throws {
        if camera.captureMode != .video {
            let setCameraMode = SetCaptureModeTool(camera: camera, uiManager: toolUIManager)
            _ = try await setCameraMode.call(arguments: .init(mode: .video))
        }
        
        let startVideo = StartVideoTool(camera: camera, uiManager: toolUIManager)
        _ = try await startVideo.call(arguments: .init())
    }
    
    private func stopRecordingVideo() async throws {
        let stopVideo = StopVideoTool(camera: camera, uiManager: toolUIManager)
        _ = try await stopVideo.call(arguments: .init())
    }
}

extension String {
    func replacingOccurrences(of targets: [Self], with replacement: Self) -> Self {
        var result = self
        for target in targets {
            result = result.replacingOccurrences(of: target, with: replacement)
        }
        return result
    }
}

//func AudioServicesPlaySystemSound(_ soundID: SystemSoundID) async {
//    await withCheckedContinuation { continuation in
//        AudioServicesPlaySystemSoundWithCompletion(soundID) {
//            continuation.resume()
//        }
//    }
//}

private let llmInstructions: String = "You are Teddy, a helpful camera app designed to help people with fine motor issues use a camera with powerfull advanced multi-chain action capabilities. Please note that all input you receive has been translated from voice to text. Do not change the name unless you are specifically told your new name."

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
    
    /// Tracks if Teddy is actively listening (wake word not needed)
    private(set) var isActiveListening = false
    
    func setActiveListening(_ isActive: Bool) {
        isActiveListening = isActive
    }
    
    /// Tracks if the user has onboarded
    private(set) var isOnboarding: Bool = false
    
    @MainActor
    func setOnboarding(_ isOnboarding: Bool) {
        self.isOnboarding = isOnboarding
    }
    
    /// Triggers the countdown animation. The animation is 5 seconds long.
    private(set) var countdownTrigger: Bool = false
    
    func triggerCountdown() {
        countdownTrigger.toggle()
    }
    
    private(set) var assistantName: String = UserDefaults.standard.string(forKey: "assistantName") ?? "Teddy" {
        didSet {
            UserDefaults.standard.set(assistantName, forKey: "assistantName")
        }
    }
    
    var assistantNameBinding: Binding<String> {
        .init(
            get: { self.assistantName },
            set: { self.setAssistantName($0) }
        )
    }
    
    func setAssistantName(_ name: String) {
        self.assistantName = name
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
