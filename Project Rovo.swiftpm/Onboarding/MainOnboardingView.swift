//
//  MainOnboardingView.swift
//  Project Rovo
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI

@Observable
final class OnboardingStepManager {
    private(set) var step: OnboardingSteps = .intro
    var isBack = false
    
    func next() {
        isBack = false
        withAnimation {
            step.next()
        }
    }
    func previous() {
        isBack = true
        withAnimation {
            step.previous()
        }
    }
}

enum OnboardingSteps: Int, ViewSteps {
    case intro
}

struct MainOnboardingView: View {
    @State var stepManager = OnboardingStepManager()
    
    var body: some View {
        VStack {
            switch stepManager.step {
            case .intro:
                OnboardingIntroView()
                    .backForward(isBack: stepManager.isBack)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .environment(stepManager)
    }
}
