import SwiftUI
import FoundationModels

struct ContentView: View {
    @StateObject var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State var modelController = VoiceActivatedFMController()
    
    var body: some View {
        VStack {
            Group {
                Image(systemName: "music.microphone")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Project Rovo")
            }
                .font(.largeTitle)
            Spacer()
            Text(speechRecognizer.transcript.components(separatedBy: " ").suffix(9).joined(separator: " "))
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
            if let modelResponse = modelController.modelResponse, !NSAttributedString(modelResponse).string.isEmpty {
                GroupBox {
                    ScrollViewReader { proxy in
                        DynamicScrollView(maxHeight: 200) {
                            Text(modelResponse)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .id("model_response")
                        }
                        .onChange(of: modelResponse) {
                            proxy.scrollTo("model_response", anchor: .bottom)
                        }
                    }
                }
            }
            Button {
                switch isRecording {
                case true:
                    endTranscription()
                    modelController.respondTask?.cancel()
                case false:
                    startTranscription()
                }
            } label: {
                switch isRecording {
                case true:
                    Label("Recording...", systemImage: "record.circle")
                        .foregroundStyle(.red)
                case false:
                    Label("Paused", systemImage: "pause")
                }
            }
            .labelStyle(.titleAndIcon)
            .font(.title3)
        }
        .padding()
        .onAppear {
            startTranscription()
        }
        .onChange(of: speechRecognizer.transcript) {
            Task {
                let didRespond = await modelController.pendModelResponse(from: Binding(get: { speechRecognizer.transcript }, set: {_ in}))
                if didRespond {
                    startTranscription()
                }
            }
        }
    }
    
    private func startTranscription() {
        speechRecognizer.resetTranscript()
        speechRecognizer.startTranscribing()
        isRecording = true
    }
    
    private func endTranscription() {
        speechRecognizer.stopTranscribing()
        isRecording = false
    }
}

extension AttributedString {
    init(styledMarkdown markdownString: String) throws {
        let newLine = AttributedString("\n")
        let markdownString = markdownString
            .replacingOccurrences(of: "\n\n", with: "\u{2029}\u{2029}\n\n")
        
        var output = try AttributedString(
            markdown: markdownString,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            ),
            baseURL: nil
        )
        
        while let range = output.range(of: "\u{2029}\u{2029}") {
            output[range] = newLine[newLine.startIndex..<newLine.endIndex]
        }

        for (intentBlock, intentRange) in output.runs[AttributeScopes.FoundationAttributes.PresentationIntentAttribute.self].reversed() {
            guard let intentBlock = intentBlock else { continue }
            for intent in intentBlock.components {
                switch intent.kind {
                case .header(level: let level):
                    switch level {
                    case 1:
                        output[intentRange].font = .system(.title).bold()
                    case 2:
                        output[intentRange].font = .system(.title2).bold()
                    case 3:
                        output[intentRange].font = .system(.title3).bold()
                    default:
                        break
                    }
                default:
                    break
                }
            }
            
            if intentRange.lowerBound != output.startIndex {
                output.characters.insert(contentsOf: "\n", at: intentRange.lowerBound)
            }
        }

        self = output
    }
}
