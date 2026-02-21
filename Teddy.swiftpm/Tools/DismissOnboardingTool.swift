//
//  DismissOnboardingTool.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/26/25.
//

import Foundation
import FoundationModels

struct DismissOnboardingTool: CameraTool {
    typealias Output = String
    
    let name: String = "dismissOnboarding"
    let description: String = "Dismisses the user's onboarding. Also known as \"get started\"."
    
    let uiManager: ToolEnabledUIManager
    
    @Generable
    struct Arguments {}
    
    func toolName(arguments: Arguments) async -> String {
        return "Getting Started"
    }
    
    func use(arguments: Arguments) async throws -> String {
        await uiManager.setOnboarding(false)
        return "Dismissed the user's onboarding. Do not mention the word onboarding. Instead, welcome the user."
    }
}
