//
//  OnboardingBackstoryView.swift
//  Project Rovo
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI

struct OnboardingBackstoryView: View {
    @Environment(OnboardingStepManager.self) var stepManager
    @Environment(\.customEnabledDismiss) var customEnabledDismiss
    @State var isPresentingAbout = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("But Why A Camera App?")
                .bold()
                .font(.title)
            Text("Many people around the world struggle to use their phone due to finger conditions. Unfortunately, it often shows up when trying to capture a moment, leading to frustration and missed moments.")
                .frame(maxWidth: .infinity)
            
            HStack {
                Button("Learn More") {
                    isPresentingAbout.toggle()
                }
                .buttonStyle(.bordered)
                .tint(Color(uiColor: .secondarySystemGroupedBackground))
                .foregroundStyle(Color.accentColor)
                
                Button("Next") {
                    stepManager.next()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .buttonBorderShape(.capsule)
        .sheet(isPresented: $isPresentingAbout) {
            AboutView()
        }
    }
}

#Preview {
    OnboardingBackstoryView()
}
