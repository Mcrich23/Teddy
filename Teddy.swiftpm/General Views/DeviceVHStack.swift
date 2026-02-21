//
//  DeviceVHStack.swift
//  Teddy
//
//  Created by Morris Richman on 12/25/25.
//

import SwiftUI

struct DeviceVHStack<Content: View>: View {
    let alignment: Alignment
    let spacing: CGFloat?
    @ViewBuilder var content: Content
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(alignment: Alignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            VStack(alignment: alignment.horizontal, spacing: spacing, content: {
                self.content
            })
        } else {
            HStack(alignment: alignment.vertical, spacing: spacing, content: {
                self.content
            })
        }
    }
}
