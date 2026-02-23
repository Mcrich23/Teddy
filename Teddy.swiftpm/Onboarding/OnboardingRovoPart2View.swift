//
//  OnboardingTeddyPart2View.swift
//  Teddy
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI
import FoundationModels

struct OnboardingTeddyPart2View<CameraModel: Camera>: View {
    @Environment(OnboardingStepManager.self) var stepManager
    @Environment(\.startTranscription) var startTranscription
    @Environment(Transcriber.self) var speechRecognizer
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Meet Teddy")
                .bold()
                .font(.title)
            Text("With Teddy, you just tell it what to do, and it figure out the rest. No strict commands, just say the wake word \(Text("Teddy").bold()) and give it your idea.")
            
            Group {
                #if !targetEnvironment(simulator)
                if let startTranscription, SystemLanguageModel.default.isAvailable {
                    GroupBox {
                        Text("Say \(Text("\"Teddy, get started\"").bold()) to begin.")
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
            SpeechTranscriptionView<CameraModel>()
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
