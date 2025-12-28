//
//  SwitchCameraTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels
@preconcurrency import AVFoundation

struct SwitchCameraTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "switchCamera"
    let description: String = "Switches to the specified camera. If no position is specified, it will switch to the next available camera."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {
        let cameraPosition: CameraPosition?
    }
    
    func toolName(arguments: Arguments) async -> String {
        guard let cameraPosition = arguments.cameraPosition else {
            return "Switching Camera"
        }
        
        return "Switching to \(cameraPosition.rawValue.capitalized) camera"
    }
    
    func use(arguments: Arguments) async throws -> String {
        let device = try await camera.switchVideoDevices(to: arguments.cameraPosition)
        await uiManager.flipCamera()
        return "Now using the \(device) camera."
    }
}

struct GetAvailableCamerasTool<CameraModel: Camera>: CameraTool {
    typealias Output = [CameraPosition]
    
    let name: String = "getCameras"
    let description: String = "Returns all available camera positions."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {}
    
    func toolName(arguments: Arguments) async -> String {
        "Getting Cameras"
    }
    
    func use(arguments: Arguments) async throws -> [CameraPosition] {
        return await Array(camera.availableCameras.keys)
    }
}
