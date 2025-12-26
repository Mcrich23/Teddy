/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface for the sample app.
*/

import SwiftUI
import AVFoundation
import AVKit

@MainActor
struct CameraView<CameraModel: Camera>: PlatformView {
    @StateObject var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State var modelController = VoiceActivatedFMController()
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    // The direction a person swipes on the camera preview or mode selector.
    @State var swipeDirection = SwipeDirection.left
    
    var body: some View {
        ZStack {
            // A container view that manages the placement of the preview.
            PreviewContainer(camera: camera) {
                // A view that provides a preview of the captured content.
                CameraPreview(source: camera.previewSource)
                    // Handle capture events from device hardware buttons.
                    .onCameraCaptureEvent { event in
                        if event.phase == .ended {
                            Task {
                                switch camera.captureMode {
                                case .photo:
                                    // Capture a photo when pressing a hardware button.
                                    await camera.capturePhoto()
                                case .video:
                                    // Toggle video recording when pressing a hardware button.
                                    await camera.toggleRecording()
                                }
                            }
                        }
                    }
                    // Focus and expose at the tapped point.
                    .onTapGesture { location in
                        Task { await camera.focusAndExpose(at: location) }
                    }
                    // Switch between capture modes by swiping left and right.
                    .simultaneousGesture(swipeGesture)
                    /// The value of `shouldFlashScreen` changes briefly to `true` when capture
                    /// starts, and then immediately changes to `false`. Use this change to
                    /// flash the screen to provide visual feedback when capturing photos.
                    .opacity(camera.shouldFlashScreen ? 0 : 1)
            }
            .ignoresSafeArea()
            // The main camera user interface.
            CameraUI(camera: camera, swipeDirection: $swipeDirection)
        }
        .onAppear {
            camera.fetchLastPhoto()
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
        .environment(modelController)
        .environmentObject(speechRecognizer)
    }

    var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded {
                // Capture swipe direction.
                swipeDirection = $0.translation.width < 0 ? .left : .right
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

#Preview {
    CameraView(camera: PreviewCameraModel())
}

enum SwipeDirection {
    case left
    case right
    case up
    case down
}
