//
//  MainOnboardingView.swift
//  Project Rovo
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI

@Observable
final class OnboardingStepManager {
    fileprivate var dismiss: CustomDismissAction = .init(action: {})
    
    private(set) var step: OnboardingSteps = .intro
    var isBack = false
    
    func next() {
        isBack = false
        guard step.rawValue < OnboardingSteps.allCases.count - 1 else {
            dismiss.action()
            return
        }
        
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
    case intro, backstory, rovoPart1, rovoPart2
}

struct MainOnboardingView<CameraModel: Camera>: View {
    @State var stepManager = OnboardingStepManager()
    @Environment(\.customEnabledDismissAction) var customEnabledDismissAction
    
    var body: some View {
        VStack {
            switch stepManager.step {
            case .intro:
                OnboardingIntroView()
                    .padding()
                    .fillSpaceAvailable()
                    .backForward(isBack: stepManager.isBack)
            case .backstory:
                OnboardingBackstoryView()
                    .padding()
                    .fillSpaceAvailable()
                    .backForward(isBack: stepManager.isBack)
            case .rovoPart1:
                OnboardingRovoPart1View()
                    .padding()
                    .fillSpaceAvailable()
                    .backForward(isBack: stepManager.isBack)
            case .rovoPart2:
                OnboardingRovoPart2View<CameraModel>()
                    .padding()
                    .fillSpaceAvailable()
                    .backForward(isBack: stepManager.isBack)
            }
        }
        .tint(Color.accentColor.mix(with: .black, by: 0.1))
        .environment(stepManager)
        .onChange(of: customEnabledDismissAction, initial: true) { oldValue, newValue in
            stepManager.dismiss = newValue
        }
        .onAppear {
            ActiveListentingTip.isAvailable = false
        }
        .onDisappear {
            ActiveListentingTip.isAvailable = true
        }
    }
}
