//
//  SetFlashModeTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import SwiftUI
import FoundationModels

struct SetFlashModeTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "setFlashMode"
    let description: String = "Switches the flash mode."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {
        let mode: FlashMode
    }
    
    func toolName(arguments: Arguments) async -> String {
        "Switching to \(arguments.mode) flash mode"
    }
    
    func use(arguments: Arguments) async throws -> String {
        Task { @MainActor in
            withAnimation {
                camera.flashMode = arguments.mode
            }
        }
        return "Switched to \(arguments.mode) flash mode."
    }
}
