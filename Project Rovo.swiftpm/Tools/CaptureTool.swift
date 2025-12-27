//
//  CaptureTool.swift
//  Project Ravo
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
        Task { @MainActor in
            camera.captureMode = .photo
            await camera.capturePhoto()
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
            Task { @MainActor in
                camera.captureMode = .video
                await camera.toggleRecording()
                return "Video Started"
            }
            return "Photo Taken"
        }
    }
}

struct StopVideoTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "stopVideo"
    let description: String = "Stops the video capture."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {}
    
    func toolName(arguments: Arguments) async -> String {
        "Stopping Video"
    }
    
    func use(arguments: Arguments) async throws -> String {
        await camera.toggleRecording()
        return "Video Stopped"
    }
}
