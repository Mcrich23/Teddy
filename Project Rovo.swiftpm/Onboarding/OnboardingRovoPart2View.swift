//
//  OnboardingRovoPart2View.swift
//  Project Rovo
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI
import FoundationModels

struct OnboardingRovoPart2View: View {
    @Environment(OnboardingStepManager.self) var stepManager
    @Environment(\.startTranscription) var startTranscription
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Meet Rovo")
                .bold()
                .font(.title)
            Text("With Rovo, you just tell it what to do, and it figure out the rest. No strict commands, just say the wake word \(Text("Rovo").bold()) and give it your idea.")
            
            Group {
                #if !targetEnvironment(simulator)
                if let startTranscription, SystemLanguageModel.default.isAvailable {
                    GroupBox {
                        Text("Say \(Text("\"Rovo, get started\"").bold()) to begin.")
                    }
                    .onAppear {
                        startTranscription()
                    }
                } else {
                    getStartedButton
                }
                #else
                getStartedButton
                #endif
            }
            .padding(.top)
        }
        .buttonBorderShape(.capsule)
        .frame(maxHeight: .infinity, alignment: .center)
        .overlay(alignment: .bottom) {
            SpeechTranscriptionView()
        }
    }
    
    @ViewBuilder
    var getStartedButton: some View {
        Button("Get Started") {
            stepManager.next()
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    OnboardingBackstoryView()
}
