/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the main camera user interface.
*/

import SwiftUI
import AVFoundation

/// A view that presents the main camera user interface.
struct CameraUI<CameraModel: Camera>: PlatformView {

    @State var camera: CameraModel
    @Binding var swipeDirection: SwipeDirection
    @State var isShowingFlashMenu = false
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.orientation) var orientation
    
    @Environment(VoiceActivatedFMController.self) var modelController
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    
    /// The `CGRect` for the UI.
    ///
    /// - Important: For performance purposes, this is only set when using the compact UI.
    @State private var uiRect: CGRect?
    
    /// Hides flash menu if other area is tapped
    @ViewBuilder
    var dismissFlashMenuRectangle: some View {
        if isShowingFlashMenu || camera.isPrecisionZooming {
            Rectangle()
                .opacity(0.001)
            //                    .layoutPriority(-1)
                .onTapGesture {
                    isShowingFlashMenu = false
                    withAnimation {
                        camera.isPrecisionZooming = false
                    }
                }
                .accessibilityHidden(true)
        }
    }
    
    var body: some View {
        Group {
            if isRegularSize {
                regularUI
            } else {
                compactUI
            }
        }
        .overlay {
            StatusOverlayView(status: camera.status)
        }
    }
    
    /// This view arranges UI elements vertically.
    @ViewBuilder
    var compactUI: some View {
        VStack(spacing: 0) {
            FeaturesToolbar(camera: camera, isShowingFlashMenu: $isShowingFlashMenu, dismissFlashMenuRectangle: dismissFlashMenuRectangle)
                .padding(.bottom)
                .background(Color.black.opacity(0.3))
                .zIndex(2)
            
            VStack(spacing: 0) {
                ZStack {
                    Spacer()
                        .overlay {
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
                                .padding(.horizontal)
                            }
                        }
                    
                    dismissFlashMenuRectangle
                }
                
                ZoomModeView(camera: camera)
                    .padding(.bottom)
                    .overlay {
                        if !camera.isPrecisionZooming {
                            dismissFlashMenuRectangle
                        }
                    }
            }
            .overlay(alignment: .leading) {
                if orientation.isLandscape {
                    CameraUIBadgeOverlay(camera: camera)
                        .rotationEffect(.degrees(90))
                        .padding(.leading, -30)
                        .animation(.default, value: orientation)
                }
            }
            
            VStack(spacing: 0) {
                MainToolbar(camera: camera)
                    .materialOpacity(0.8)
                    .padding(.bottom)
                CaptureModeView(camera: camera, direction: $swipeDirection)
                    .materialOpacity(0.6)
                    .padding(.bottom, bottomPadding)
                
                Group {
                    if speechRecognizer.transcript.isEmpty {
                        Text(" ")
                    } else {
                        Text(speechRecognizer.transcript.components(separatedBy: " ").suffix(6).joined(separator: " "))
                    }
                }
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
            }
            .background(Color.black.opacity(0.3).padding(.top, bottomPadding/2).padding(.bottom, -bottomPadding))
            .overlay {
                dismissFlashMenuRectangle
            }
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { newValue in
            uiRect = newValue
        }

    }
    
    /// This view arranges UI elements in a layered stack.
    @ViewBuilder
    var regularUI: some View {
        HStack {
            Spacer()
            VStack {
                FeaturesToolbar(camera: camera, isShowingFlashMenu: $isShowingFlashMenu, dismissFlashMenuRectangle: dismissFlashMenuRectangle)
                Group {
                    MainToolbar(camera: camera)
                    
                    CaptureModeView(camera: camera, direction: $swipeDirection)
                }
                .overlay {
                    dismissFlashMenuRectangle
                }
            }
        }
        .overlay(alignment: .top) {
            CameraUIBadgeOverlay(camera: camera)
        }
        .padding(.trailing)
    }
    
    var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded {
                // Capture the swipe direction.
                swipeDirection = $0.translation.width < 0 ? .left : .right
            }
    }
    
    var bottomPadding: CGFloat {
        // Dynamically calculate the offset for the bottom toolbar in iOS.
        guard let uiRect else { return 0 }
        let rect = AVMakeRect(aspectRatio: movieAspectRatio, insideRect: uiRect)
        let padding = (rect.minY.rounded() / 2) + 12
        return padding
    }
}

#Preview {
    CameraUI(camera: PreviewCameraModel(), swipeDirection: .constant(.left))
}
