//
//  ActiveListeningButton.swift
//  Project Rovo
//
//  Created by Morris Richman on 12/31/25.
//

import SwiftUI
import TipKit

///  A button to toggle the enabled state of LLM active listening
struct ActiveListeningButton<CameraModel: Camera>: PlatformView {
    let camera: CameraModel
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(ToolEnabledUIManager.self) var toolUIManager
    
    var isEnabled: Bool {
        toolUIManager.isActiveListening && !camera.captureActivity.isRecording
    }
    
    let tip = ActiveListentingTip()
    
    var body: some View {
        Button {
            tip.invalidate(reason: .actionPerformed)
            toolUIManager.setActiveListening(!toolUIManager.isActiveListening)
        } label: {
            ZStack {
                Text("\(Image(systemName: "microphone"))R")
                    .font(.callout.weight(.semibold))
                Image(systemName: isEnabled ? "circle" : "circle.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(!isEnabled ? .white : .clear, .clear)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    .allowsHitTesting(false)
            }
                .frame(width: 30, height: 30)
        }
        .accessibilityLabel(Text(isEnabled ? "Disable Active Listening" : "Enable Active Listening"))
        .opacity(camera.prefersMinimizedUI ? 0 : 1)
        .buttonStyle(DefaultButtonStyle(size: isRegularSize ? .large : .small))
        .disabled(camera.captureActivity.isRecording)
        .popoverTip(tip)
    }
}

struct ActiveListentingTip: Tip {
    @Parameter
    static var isAvailable: Bool = false
    
    var rules: [Rule] {
        #Rule(Self.$isAvailable) {
            $0 == true
        }
    }
    
    var title: Text { Text("Did you know?") }
    var message: Text? {
        Text("You can tell Rovo more things without saying \"Rovo\" through Active Listening.")
    }
    var image: Image? { Image(systemName: "microphone") }
}
