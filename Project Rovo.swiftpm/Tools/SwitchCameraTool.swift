//
//  SwitchCameraTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels
@preconcurrency import AVFoundation

struct SwitchCameraTool<CameraModel: Camera>: CameraTool {
    typealias Output = String
    
    let name: String = "switchCamera"
    let description: String = "Switches to the specified camera. If no device type is specified, it will switch to the next available camera."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {
        let deviceType: String?
    }
    
    func toolName(arguments: Arguments) async -> String {
        "Switching Camera"
    }
    
    func use(arguments: Arguments) async throws -> String {
        var avDevice: AVCaptureDevice?
        
        if let deviceTypeString = arguments.deviceType {
            let deviceType = AVCaptureDevice.DeviceType(rawValue: deviceTypeString)
            avDevice = await camera.availableCameras.first(where: { $0.value.deviceType == deviceType })?.value
        }
        let device = try await camera.switchVideoDevices(to: avDevice)
        await uiManager.flipCamera()
        return "Now using the \(device) camera."
    }
}

struct GetAvailableCamerasTool<CameraModel: Camera>: CameraTool {
    typealias Output = [AVCaptureDevice.DeviceType.RawValue]
    
    let name: String = "getCameras"
    let description: String = "Returns all available camera device types."
    
    let camera: CameraModel
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {}
    
    func toolName(arguments: Arguments) async -> String {
        "Getting Cameras"
    }
    
    func use(arguments: Arguments) async throws -> [AVCaptureDevice.DeviceType.RawValue] {
        return await camera.availableCameras.values.map(\.deviceType.rawValue)
    }
}
