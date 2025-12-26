//
//  SetFlashModeTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct SetFlashModeTool<CameraModel: Camera>: Tool {
    let name: String = "setFlashMode"
    let description: String = "Switches the flash mode."
    
    let camera: CameraModel
    
    @Generable
    struct Arguments {
        let mode: FlashMode
    }
    
    func call(arguments: Arguments) async throws -> String {
        Task { @MainActor in
            camera.flashMode = arguments.mode
        }
        return "Switched to \(arguments.mode) flash mode."
    }
}
