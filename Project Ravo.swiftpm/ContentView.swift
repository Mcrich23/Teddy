import SwiftUI
import FoundationModels

struct ContentView: View {
    @StateObject var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var modelResponse: AttributedString?
    private let session = LanguageModelSession()
    
    var body: some View {
        VStack {
            Group {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Project Ravo")
            }
                .font(.largeTitle)
            Spacer()
            Text(speechRecognizer.transcript)
                .fixedSize(horizontal: false, vertical: true)
            if let modelResponse, !NSAttributedString(modelResponse).string.isEmpty {
                GroupBox {
                    ScrollView {
                        Text(modelResponse)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(maxHeight: 200)
                    .layoutPriority(-1)
                }
            }
            Button(isRecording ? "Stop" : "Record", systemImage: isRecording ? "pause" : "record.circle") {
                switch isRecording {
                case true:
                    endTranscription()
                case false:
                    startTranscription()
                }
            }
            .disabled(session.isResponding)
        }
        .padding()
    }
    
    private func startTranscription() {
        speechRecognizer.resetTranscript()
        speechRecognizer.startTranscribing()
        isRecording = true
    }
    
    private func endTranscription() {
        speechRecognizer.stopTranscribing()
        isRecording = false
        Task {
            do {
                try await getModelResponse()
            } catch {
                print(error)
            }
        }
    }
    
    private func getModelResponse() async throws {
        guard !session.isResponding else { return }
        let stream = session.streamResponse(to: speechRecognizer.transcript)
        
        for try await chunk in stream {
            modelResponse = try? AttributedString(styledMarkdown: chunk.content)
        }
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
