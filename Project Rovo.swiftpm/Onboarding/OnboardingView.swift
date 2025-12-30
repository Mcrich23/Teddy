//
//  OnboardingView.swift
//  Project Rovo
//
//  Created by Morris Richman on 12/29/25.
//

import SwiftUI

enum OnboardingSteps: Int, CaseIterable, ViewSteps {
    case start
}

struct OnboardingView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    OnboardingView()
}
