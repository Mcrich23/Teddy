//
//  SetCaptureModeTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct SetCaptureModeTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "setCaptureMode"
    let description: String = "Switches the capture mode."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {
        let mode: CaptureMode
    }
    
    func toolName(arguments: Arguments) async -> String {
        return "Switching to \(arguments.mode) capture mode"
    }
    
    func use(arguments: Arguments) async throws -> String {
        await camera.setCaptureMode(arguments.mode)
        return "Switched to \(arguments.mode) capture mode."
    }
}
