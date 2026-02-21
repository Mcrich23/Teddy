//
//  CameraToolProtocol.swift
//  Teddy
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

protocol CameraTool: Tool {
    var uiManager: ToolEnabledUIManager { get }
    func toolName(arguments: Arguments) async -> String
    func use(arguments: Arguments) async throws -> Output
}

extension CameraTool {
    func call(arguments: Arguments) async throws -> Output {
        await uiManager.setCurrentTool(toolName(arguments: arguments))
        let output = try await use(arguments: arguments)
        await uiManager.setCurrentTool(nil)
        return output
    }
}
