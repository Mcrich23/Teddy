//
//  SetZoomTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct SetZoomTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "setZoom"
    let description: String = "Changes the zoom."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {
        let factor: ZoomFactor
    }
    
    func toolName(arguments: Arguments) async -> String {
        return "Switching to \(arguments.factor)x zoom"
    }
    
    func use(arguments: Arguments) async throws -> String {
        Task { @MainActor in
            camera.animateZoom(to: arguments.factor)
        }
        return "Switched to \(arguments.factor)x zoom."
    }
}

struct GetZoomFactorsTool<CameraModel: Camera>: CameraTool {
    typealias Output = [ZoomFactor]
    
    let name: String = "getZoomFactors"
    let description: String = "Gets the current camera's zoom factors."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {}
    
    func toolName(arguments: Arguments) async -> String {
        "Getting zoom factors"
    }
    
    func use(arguments: Arguments) async throws -> [ZoomFactor] {
        await camera.zoomFactors
    }
}

struct GetZoomTool<CameraModel: Camera>: CameraTool {
    typealias Output = ZoomFactor
    
    let name: String = "getZoom"
    let description: String = "Gets the current camera's zoom."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {}
    
    func toolName(arguments: Arguments) async -> String {
        "Getting current zoom"
    }
    
    func use(arguments: Arguments) async throws -> ZoomFactor {
        await camera.currentZoom
    }
}
