import SwiftUI

struct ContentView: View {
    @StateObject var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    
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
            Button(isRecording ? "Stop" : "Record", systemImage: isRecording ? "pause" : "record.circle") {
                switch isRecording {
                case true:
                    endTranscription()
                case false:
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
