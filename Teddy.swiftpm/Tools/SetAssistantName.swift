//
//  SetLiveTool.swift
//  Teddy
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct SetAssistantName: CameraTool {
    typealias Output = String
    
    let name: String = "setAssistantName"
    let description: String = "Changes the assistant name. Only use this when the user requests to change the name."
    
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {
        let newName: String
    }
    
    func toolName(arguments: Arguments) async -> String {
        return "Changing Assistant Name to \(arguments.newName)"
    }
    
    func use(arguments: Arguments) async throws -> String {
        await uiManager.setAssistantName(arguments.newName)
        
        return "Assistant name changed to \(arguments.newName)."
    }
}
