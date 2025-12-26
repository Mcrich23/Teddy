//
//  SetLiveTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct SetLiveTool<CameraModel: Camera>: Tool {
    let name: String = "setLiveMode"
    let description: String = "Switches the camera's live mode."
    
    let camera: CameraModel
    
    @Generable
    struct Arguments {
        let isOn: Bool
    }
    
    func call(arguments: Arguments) async throws -> String {
        Task { @MainActor in
            camera.isLivePhotoEnabled = arguments.isOn
        }
        return "Switched live mode to \(arguments.isOn)."
    }
}
