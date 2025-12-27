//
//  SetLiveTool.swift
//  Project Ravo
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
        switch arguments.isOn {
        case true:
            return "Turning Live Mode On"
        case false:
            return "Turning Live Mode Off"
        }
    }
    
    func use(arguments: Arguments) async throws -> String {
        Task { @MainActor in
            camera.isLivePhotoEnabled = arguments.isOn
        }
        return "Switched live mode to \(arguments.isOn)."
    }
}
