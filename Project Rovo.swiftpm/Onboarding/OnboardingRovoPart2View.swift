//
//  OnboardingRovoPart2View.swift
//  Project Rovo
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI

struct OnboardingRovoPart2View: View {
    @Environment(OnboardingStepManager.self) var stepManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Meet Rovo")
                .bold()
                .font(.title)
            Text("With Rovo, you just tell it what to do, and it figure out the rest. No strict commands, just say what you want.")
            
            GroupBox {
                Text("Say \(Text("Rovo get started").bold()) to begin.")
            }
            .padding(.top)
        }
        .buttonBorderShape(.capsule)
    }
}

#Preview {
    OnboardingBackstoryView()
}
