//
//  OnboardingRovoView.swift
//  Project Rovo
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI

struct OnboardingRovoPart1View: View {
    @Environment(OnboardingStepManager.self) var stepManager
    @State var isPresentingAbout = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Fixing That With Rovo")
                .bold()
                .font(.title)
            Text("A notable population who has difficulty using touch devices are those slightly more advanced in age who did not grow up with touch interfaces. The same people often have difficulty learning accessibility systems or refuse to use them do to their personal connotation of the word. This creates more frustration towards the device.")
                .frame(maxWidth: .infinity)
            
            HStack {
                Button("My Story") {
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
