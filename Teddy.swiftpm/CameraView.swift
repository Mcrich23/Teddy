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
    @State var speechRecognizer = Transcriber()
    @State var modelController: VoiceActivatedFMController<CameraModel>
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    @State var toolUIManager: ToolEnabledUIManager
    
    @State var isShowingOnboarding = false
    @AppStorage("hasOnboarded") var hasOnboarded = false
    
    init(camera: CameraModel) {
        self.camera = camera
        let toolUIManager = ToolEnabledUIManager()
        self.toolUIManager = toolUIManager
        self.modelController = VoiceActivatedFMController(camera: camera, toolUIManager: toolUIManager)
    }
    
    // The direction a person swipes on the camera preview or mode selector.
    @State var swipeDirection = SwipeDirection.left
    
    var body: some View {
        ZStack {
            // A container view that manages the placement of the preview.
            PreviewContainer(camera: camera) {
                // A view that provides a preview of the captured content.
                CameraPreview(camera: camera)
                    // Handle capture events from device hardware buttons.
                    .onCameraCaptureEvent { event in
                        guard !toolUIManager.isOnboarding else { return }
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .simultaneousGesture(TapGesture().onEnded({ _ in
            modelController.stopTemporaryListening()
        }))
        .onChange(of: toolUIManager.isOnboarding, { oldValue, newValue in
            hasOnboarded = !newValue
            Task {
                try? await Task.sleep(for: .seconds(1))
                isShowingOnboarding = newValue
            }
        })
        .overlay(content: {
            GlassView(variant: toolUIManager.isOnboarding ? 2 : nil, animation: glassOnboardingAnimation)
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(toolUIManager.isOnboarding) // Allow tap underneath glass layer
                .overlay {
                    Group {
                        if toolUIManager.isOnboarding {
                            MainOnboardingView<CameraModel>()
                                .transition(.blurReplace)
                                .customDismiss {
                                    toolUIManager.setOnboarding(false)
                                    startTranscription()
                                }
                        }
                    }
                    .animation(viewOnboardingAnimation, value: toolUIManager.isOnboarding)
                }
        })
        .onAppear {
            if !hasOnboarded {
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    toolUIManager.setOnboarding(true)
                }
            } else {
                startTranscription()
                ActiveListentingTip.isAvailable = true
            }
        }
        .onChange(of: speechRecognizer.transcript) {
            Task {
                let didRespond = await modelController.pendModelResponse(from: Binding(get: { speechRecognizer.transcript }, set: {_ in}))
                if didRespond {
                    endTranscription()
                    startTranscription()
                }
            }
        }
        .environment(modelController)
        .environment(toolUIManager)
        .environment(speechRecognizer)
        .environment(\.startTranscription, startTranscription)
        .environment(\.endTranscription, endTranscription)
    }
    
    var glassOnboardingAnimation: Animation {
        switch isShowingOnboarding {
        case true:
            return .easeInOut.speed(0.5).delay(0.1)
        case false:
            return .easeInOut.speed(0.5)
        }
    }
    
    var viewOnboardingAnimation: Animation {
        switch isShowingOnboarding {
        case true:
            return .easeInOut.speed(0.75)
        case false:
            return .easeInOut.speed(0.75).delay(0.3)
        }
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
    }
    
    private func endTranscription() {
        speechRecognizer.stopTranscribing()
    }
}

extension EnvironmentValues {
    @Entry var startTranscription: (() -> Void)?
    @Entry var endTranscription: (() -> Void)?
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
