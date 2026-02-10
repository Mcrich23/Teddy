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
    let description: String = "Switches to the specified camera. If no position is specified, it will switch to the next available camera. For selfies, the front camera is generally the selfie camera."
    
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
        await withAnimation {
            uiManager.flipCamera()
        }
        let device = try await camera.switchVideoDevices(to: arguments.cameraPosition)
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
