//
//  AboutView.swift
//  Project Rovo
//
//  Created by Morris Richman on 12/29/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 30) {
                    HStack {
                        Image(.rovo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding()
                        VStack(alignment: .leading) {
                            Text("About Project Rovo")
                                .font(.largeTitle)
                                .bold()
                        }
                    }
                    
                    Section {
                        Text("Project Rovo was created in loving memory of Laurence\u{00a0}N.\u{00a0}Smith")
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        LarrySmithBioView()
                    }
                }
                .padding()
            }
        }
    }
}

private struct LarrySmithBioView: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Group {
                    bio
                    image
                }
                    .frame(minWidth: 175, maxWidth: 250)
            }
            VStack {
                    image
                        .frame(maxHeight: 150)
                    bio
            }
        }
    }
    
    var image: some View {
        Image(.larrySmith)
            .resizable()
            .aspectRatio(0.6667362706, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    var bio: some View {
        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
    }
}

#Preview {
    AboutView()
}
