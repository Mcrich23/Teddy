//
//  CaptureTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct CaptureTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "startCapture"
    let description: String = "Captures a new photo or video based on the current settings."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {}
    
    func toolName(arguments: Arguments) async -> String {
        switch await camera.captureMode {
        case .photo:
            return "Taking Photo"
        case .video:
            return "Starting Video"
        }
    }
    
    func use(arguments: Arguments) async throws -> String {
        switch await camera.captureMode {
        case .photo:
            await camera.capturePhoto()
            return "Photo Taken"
        case .video:
            if await camera.captureActivity.isRecording {
                return "Video is already recording"
            } else {
                await camera.toggleRecording()
                return "Video Started"
            }
        }
    }
}
