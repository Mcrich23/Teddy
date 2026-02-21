//
//  OnboardingIntroView.swift
//  Teddy
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI

struct OnboardingIntroView: View {
    @Environment(OnboardingStepManager.self) var stepManager
    
    var body: some View {
        VStack {
            Text("Welcome to Teddy")
                .bold()
                .font(.title)
            Text("You're about to experience the future of accessibility through the lens of a camera.")
            Button("Get Started") {
                stepManager.next()
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    OnboardingIntroView()
}
