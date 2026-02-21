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
    let description: String = "Changes the zoom. To zoom all of the way out, zoom to 0. To zoom all the way in, zoom to 1000. These zoom parameters will be overriden by the boundaries."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {
        let factor: ZoomFactor
    }
    
    func toolName(arguments: Arguments) async -> String {
        return await "Zooming to \(normalizeZoom(arguments.factor).value)x"
    }
    
    func use(arguments: Arguments) async throws -> String {
        Task { @MainActor in
            camera.animateZoom(to: arguments.factor)
        }
        
        return await "Zoomed to \(normalizeZoom(arguments.factor).value)x."
    }
    
    func normalizeZoom(_ zoom: ZoomFactor) async -> ZoomFactor {
        let zoomFactors = await camera.zoomFactors
        guard zoomFactors != [1] else {
            return ZoomFactor(max(1, min(zoom.value, 4)))
        }
        
        let normalizedZoom = max(Float(zoomFactors.first?.value ?? 1), min(zoom.value, powf(zoomFactors.last?.value ?? Float(zoomFactors.first?.value ?? 1), 2)))
        
        return ZoomFactor(normalizedZoom)
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
