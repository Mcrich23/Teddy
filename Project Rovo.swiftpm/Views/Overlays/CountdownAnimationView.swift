//
//  SwiftUIView.swift
//  Project Rovo
//
//  Created by Morris Richman on 2/13/26.
//

import SwiftUI

private struct CountdownAnimation: Animatable {
    var scale = 2.0
    var opacity = 0.0
}

struct CountdownAnimationView: View {
    private let initialValue = CountdownAnimation()
    
    var body: some View {
        ZStack {
            NumberView(number: "3")
                .keyframeAnimator(initialValue: initialValue) { content, value in
                    content
                        .scaleEffect(value.scale)
                        .opacity(value.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(0, duration: 2)
                        CubicKeyframe(0, duration: 3)
                    }
                    KeyframeTrack(\.opacity) {
                        CubicKeyframe(0, duration: 0.5)
                        CubicKeyframe(1, duration: 0.5)
                        CubicKeyframe(0, duration: 0.5)
                        CubicKeyframe(0, duration: 3.5)
                    }
                }
            NumberView(number: "2")
                .keyframeAnimator(initialValue: initialValue) { content, value in
                    content
                        .scaleEffect(value.scale)
                        .opacity(value.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        LinearKeyframe(initialValue.scale, duration: 1)
                        CubicKeyframe(0, duration: 2)
                        CubicKeyframe(0, duration: 2)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(initialValue.opacity, duration: 1)
                        CubicKeyframe(0, duration: 0.5)
                        CubicKeyframe(1, duration: 0.5)
                        CubicKeyframe(0, duration: 0.5)
                        CubicKeyframe(0, duration: 2.5)
                    }
                }
            NumberView(number: "1")
                .keyframeAnimator(initialValue: initialValue) { content, value in
                    content
                        .scaleEffect(value.scale)
                        .opacity(value.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        LinearKeyframe(initialValue.scale, duration: 2)
                        CubicKeyframe(0, duration: 2)
                        CubicKeyframe(0, duration: 1)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(initialValue.opacity, duration: 2)
                        CubicKeyframe(0, duration: 0.5)
                        CubicKeyframe(1, duration: 0.5)
                        CubicKeyframe(0, duration: 0.5)
                        CubicKeyframe(0, duration: 1.5)
                    }
                }
        }
    }
}

private struct NumberView: View {
    let number: String
    
    var body: some View {
        Text(number)
            .font(.system(size: 300))
            .dynamicTypeSize(.medium)
    }
}

#Preview {
    CountdownAnimationView()
}
