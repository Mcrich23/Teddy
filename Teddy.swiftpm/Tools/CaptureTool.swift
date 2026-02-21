//
//  CaptureTool.swift
//  Teddy
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct TakePhotoTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "takePhoto"
    let description: String = "Captures a new photo."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {}
    
    func toolName(arguments: Arguments) async -> String {
        return "Taking Photo"
    }
    
    func use(arguments: Arguments) async throws -> String {
        await camera.setCaptureMode(.photo)
        await uiManager.triggerCountdown()
        do {
            try await Task.sleep(for: .milliseconds(3500))
            await camera.capturePhoto()
        } catch {
            print("Take Photo Tool Error: \(error)")
        }
        return "Photo Taken"
    }
}

struct StartVideoTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "startVideo"
    let description: String = "Starts recording a new video."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {}
    
    func toolName(arguments: Arguments) async -> String {
        return "Starting Video"
    }
    
    func use(arguments: Arguments) async throws -> String {
        if await camera.captureActivity.isRecording {
            return "Video is already recording"
        } else {
            await camera.setCaptureMode(.video)
            await uiManager.triggerCountdown()
            do {
                try await Task.sleep(for: .milliseconds(3500))
                await camera.toggleRecording()
            } catch {
                print("Start Video Tool Error: \(error)")
            }
            try await Task.sleep(for: .seconds(1))
            return "Video Started"
        }
    }
}

struct StopVideoTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "stopVideo"
    let description: String = "Stops the video capture."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    let sounds = Sounds()
    
    @Generable
    struct Arguments {}
    
    func toolName(arguments: Arguments) async -> String {
        "Stopping Video"
    }
    
    func use(arguments: Arguments) async throws -> String {
        Task {
            await camera.toggleRecording()
        }
        try? await sounds.playStopRecordingSound()
        return "Video Stopped"
    }
}
