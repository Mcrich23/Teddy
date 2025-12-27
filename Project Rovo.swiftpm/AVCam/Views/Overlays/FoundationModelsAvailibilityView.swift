//
//  FoundationModelsAvailabilityView.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/27/25.
//

import SwiftUI
import FoundationModels

struct FoundationModelsAvailabilityView: View {
    private var model = SystemLanguageModel.default
    
    private var backgroundColor: Color {
        switch model.isAvailable {
        case true: .green
            case false: .red
        }
    }
    
    var body: some View {
        Group {
            switch model.availability {
            case .available:
                Text("Project Rovo is Ready!")
            case .unavailable(.deviceNotEligible):
                Text("Your Device Doesn't Support Project Rovo.")
            case .unavailable(.appleIntelligenceNotEnabled):
                Text("Please Enable Apple Intelligence to Use Project Rovo")
            case .unavailable(.modelNotReady):
                Text("Project Rovo is still initializing. Please wait...")
            case .unavailable(_):
                Text("Project Rovo is currently unavailable. Please try again later.")
            }
        }
        .padding()
        .glassEffect(.regular.tint(backgroundColor))
    }
}

#Preview {
    FoundationModelsAvailabilityView()
}
