//
//  SetActiveListeningTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct SetActiveListeningTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "setActiveListeningMode"
    let description: String = "Switches the app's active listening mode for voice commands."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {
        let isOn: Bool
    }
    
    func toolName(arguments: Arguments) async -> String {
        switch arguments.isOn {
        case true:
            return "Stopping Active Listening"
        case false:
            return "Starting Active Listening"
        }
    }
    
    func use(arguments: Arguments) async throws -> String {
        await uiManager.setActiveListening(arguments.isOn)
        switch arguments.isOn {
            case true:
            return "Now Actively Listening"
        case false:
            return "No Longer Actively Listening"
        }
    }
}
