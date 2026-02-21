//
//  SetLiveTool.swift
//  Teddy
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct SetLiveTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "setLiveMode"
    let description: String = "Switches the camera's live mode."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {
        let isOn: Bool
    }
    
    func toolName(arguments: Arguments) async -> String {
        guard await camera.captureMode == .photo else {
            return "Checking Live Mode"
        }
        
        switch arguments.isOn {
        case true:
            return "Enabling Live Mode"
        case false:
            return "Disabling Live Mode"
        }
    }
    
    func use(arguments: Arguments) async throws -> String {
        guard await camera.captureMode == .photo else {
            return "The current camera device is not in photo capture mode and therefore does not support live mode."
        }
        
        Task { @MainActor in
            camera.isLivePhotoEnabled = arguments.isOn
        }
        
        switch arguments.isOn {
        case true:
            return "Enabled Live Mode"
            case false:
            return "Disabled Live Mode"
        }
    }
}
