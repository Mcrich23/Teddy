//
//  SwiftUIView.swift
//  Teddy
//
//  Created by Morris Richman on 2/13/26.
//

import SwiftUI

private struct CountdownAnimation: Animatable {
    var scale = 2.0
    var opacity = 0.0
}

struct CountdownAnimationView: View {
    let captureMode: CaptureMode
    let animationTrigger: Bool
    @Environment(\.iconRotationAngle) var iconRotationAngle
    @State private var sounds = Sounds()
    private let initialValue = CountdownAnimation()
    
    var body: some View {
        ZStack {
            NumberView(number: "3")
                .keyframeAnimator(initialValue: initialValue, trigger: animationTrigger) { content, value in
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
                .keyframeAnimator(initialValue: initialValue, trigger: animationTrigger) { content, value in
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
                .keyframeAnimator(initialValue: initialValue, trigger: animationTrigger) { content, value in
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
        .rotationEffect(.degrees(iconRotationAngle))
        .onChange(of: animationTrigger) {
            Task {
                try await Task.sleep(for: .milliseconds(400))
                try await sounds.playCountdownNumberSound()
                try await Task.sleep(for: .milliseconds(750))
                try await sounds.playCountdownNumberSound()
                try await Task.sleep(for: .milliseconds(750))
                try await sounds.playCountdownNumberSound()
                try await Task.sleep(for: .milliseconds(400))
                
                switch captureMode {
                case .photo:
                    try await sounds.playPhotoCaptureSound()
                case .video:
                    try await sounds.playStartRecordingSound()
                }
                
                // Don't need to restart SpeechRecognizer session because the model request will do it for us.
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
    @Previewable @State var isAnimating: Bool = true
    VStack {
        CountdownAnimationView(captureMode: .photo, animationTrigger: isAnimating)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        Button("Run") {
            isAnimating.toggle()
        }
    }
}
