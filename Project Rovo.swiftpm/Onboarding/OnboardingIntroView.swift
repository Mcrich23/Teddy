//
//  OnboardingIntroView.swift
//  Project Rovo
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI

struct OnboardingIntroView: View {
    @Environment(OnboardingStepManager.self) var stepManager
    
    var body: some View {
        VStack {
            Text("Welcome to Project Rovo")
                .font(.title)
            Text("You're about to experience the future of accessibility through the lens of a camera.")
            Button("Get Started") {
                stepManager.next()
            }
            .tint(Color.accentColor.mix(with: .black, by: 0.1))
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    OnboardingIntroView()
}
