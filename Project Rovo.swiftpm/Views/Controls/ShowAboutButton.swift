//
//  ShowAboutButton.swift
//  Project Rovo
//
//  Created by Morris Richman on 12/31/25.
//

import SwiftUI

struct ShowAboutButton: View {
    @State private var isPresented: Bool = false
    var body: some View {
        Button("About Rovo", systemImage: "info.circle") {
            isPresented.toggle()
        }
        .sheet(isPresented: $isPresented) {
            AboutView()
        }
        .labelStyle(.iconOnly)
    }
}

#Preview {
    ShowAboutButton()
}
