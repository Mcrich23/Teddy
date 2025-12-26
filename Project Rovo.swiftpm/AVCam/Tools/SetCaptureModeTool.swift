//
//  SetCaptureModeTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct SetCaptureModeTool<CameraModel: Camera>: Tool {
    let name: String = "setVideo"
    let description: String = "Switches the capture mode to video."
    
    let camera: CameraModel
    
    @Generable
    struct Arguments {
        let mode: CaptureMode
    }
    
    func call(arguments: Arguments) async throws -> String {
        Task { @MainActor in
            camera.captureMode = arguments.mode
        }
        return "Switched to \(arguments.mode) capture mode."
    }
}
