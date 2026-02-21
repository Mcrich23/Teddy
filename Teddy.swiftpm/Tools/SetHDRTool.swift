//
//  SetHDRTool.swift
//  Teddy
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct SetHDRTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "setHDRMode"
    let description: String = "Switches the camera's hdr mode."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {
        let isOn: Bool
    }
    
    func toolName(arguments: Arguments) async -> String {
        guard await camera.captureMode == .video else {
            return "Checking HDR Mode"
        }
        
        switch arguments.isOn {
        case true:
            return "Enabling HDR"
        case false:
            return "Disabling HDR"
        }
    }
    
    func use(arguments: Arguments) async throws -> String {
        guard await camera.captureMode == .video else {
            return "The current camera device is not in video capture mode and therefore does not support HDR."
        }
        
        guard await camera.isHDRVideoSupported else {
            return "The current camera device does not support HDR."
        }
        
        Task { @MainActor in
            camera.isHDRVideoEnabled = arguments.isOn
        }
        
        switch arguments.isOn {
        case true:
            return "Enabled HDR"
            case false:
            return "Disabled HDR"
        }
    }
}
