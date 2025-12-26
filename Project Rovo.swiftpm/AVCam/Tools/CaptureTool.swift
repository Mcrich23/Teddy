//
//  CaptureTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct CaptureTool<CameraModel: Camera>: Tool {
    let name: String = "startCapture"
    let description: String = "Captures a new photo or video based on the current settings."
    
    let camera: CameraModel
    
    @Generable
    struct Arguments {}
    
    func call(arguments: Arguments) async throws -> String {
        switch await camera.captureMode {
        case .photo:
            await camera.capturePhoto()
            return "Photo Taken"
        case .video:
            if await camera.captureActivity.isRecording {
                return "Video is already recording"
            } else {
                await camera.toggleRecording()
                return "Video Started"
            }
        }
    }
}
