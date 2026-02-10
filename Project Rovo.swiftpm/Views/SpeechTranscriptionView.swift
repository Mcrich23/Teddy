//
//  SpeechTranscriptionView.swift
//  Project Rovo
//
//  Created by Morris Richman on 1/23/26.
//

import SwiftUI

struct SpeechTranscriptionView<CameraModel: Camera>: View {
    @Environment(ToolEnabledUIManager.self) var toolUIManager
    @Environment(VoiceActivatedFMController<CameraModel>.self) var fmController
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    
    var body: some View {
        Group {
            if let currentTool = toolUIManager.currentTool {
                HStack {
                    ProgressView()
                    Text(currentTool)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .glassEffect(in: .capsule)
            } else if fmController.isResponding {
                HStack {
                    ProgressView()
                    Text("Thinking")
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .glassEffect(in: .capsule)
            } else if speechRecognizer.transcript.isEmpty {
                Text(" ")
            } else {
                Text(speechRecognizer.transcript.components(separatedBy: " ").suffix(6).joined(separator: " "))
            }
        }
        .foregroundStyle(.white)
        .lineLimit(1)
        .fixedSize(horizontal: false, vertical: true)
    }
}
