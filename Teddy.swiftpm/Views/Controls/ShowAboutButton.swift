//
//  ShowAboutButton.swift
//  Teddy
//
//  Created by Morris Richman on 12/31/25.
//

import SwiftUI

struct ShowAboutButton: View {
    @State private var isPresented: Bool = false
    var body: some View {
        Button("About Teddy", systemImage: "info.circle") {
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
