//
//  DynamicScrollView.swift
//  Project Ravo
//
//  Created by Morris Richman on 12/21/25.
//

import SwiftUI

struct DynamicScrollView<Content: View>: View {
    let maxHeight: CGFloat
    @ViewBuilder var content: Content
    
    @State private var viewHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            if viewHeight >= maxHeight-25 {
                ScrollView {
                    content
                        .onGeometryChange(for: CGSize.self) { proxy in
                            proxy.size
                        } action: { newValue in
                            viewHeight = newValue.height
                        }
                }
                .frame(maxHeight: maxHeight)
            } else {
                content
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { newValue in
                        viewHeight = newValue.height
                    }
            }
        }
    }
}
