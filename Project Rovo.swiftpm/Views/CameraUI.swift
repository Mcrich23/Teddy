/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the main camera user interface.
*/

import SwiftUI
import AVFoundation
import FoundationModels

/// A view that presents the main camera user interface.
struct CameraUI<CameraModel: Camera>: PlatformView {

    @State var camera: CameraModel
    @Binding var swipeDirection: SwipeDirection
    @State var isShowingFlashMenu = false
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.orientation) var orientation
    @Environment(\.iconRotationAngle) var iconRotationAngle
    
    @Environment(ToolEnabledUIManager.self) var toolUIManager
    @Environment(VoiceActivatedFMController<CameraModel>.self) var modelController
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
        .overlay {
            if !SystemLanguageModel.default.isAvailable {
                FoundationModelsAvailabilityView()
            }
        }
    }
    
    /// This view arranges UI elements vertically.
    @ViewBuilder
    var compactUI: some View {
        VStack(spacing: 0) {
            FeaturesToolbar(camera: camera, isShowingFlashMenu: $isShowingFlashMenu, dismissFlashMenuRectangle: dismissFlashMenuRectangle)
                .padding(.bottom)
                .zIndex(2)
            
            VStack(spacing: 0) {
                ZStack {
                    Spacer()
                        .overlay {
                            llmResponseUI
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
            .overlay(alignment: orientation == .landscapeRight ? .leading : .trailing) {
                if orientation.isLandscape {
                    CameraUIBadgeOverlay(camera: camera)
                        .rotationEffect(.degrees(UIDevice.current.userInterfaceIdiom == .phone ? iconRotationAngle : 0))
                        .padding(orientation == .landscapeRight ? .leading : .trailing, -30)
                        .animation(.default, value: orientation)
                }
            }
            
            VStack(spacing: 0) {
                MainToolbar(camera: camera)
                    .materialOpacity(0.8)
                    .padding(.bottom)
                CaptureModeView(camera: camera, direction: $swipeDirection)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .leading) {
                        ShowAboutButton()
                            .buttonStyle(DefaultButtonStyle(size: .small))
                            .padding(.leading)
                    }
                    .materialOpacity(0.6)
                    .padding(.bottom, 15)
            }
            .overlay {
                dismissFlashMenuRectangle
            }
            .overlay(alignment: .bottom) {
                SpeechTranscriptionView()
                    .offset(y: 7)
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
            ZoomModeView(camera: camera)
            ZStack {
                Spacer()
                dismissFlashMenuRectangle
            }
            VStack(spacing: 30) {
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
        .frame(maxHeight: .infinity)
        .overlay(alignment: .top) {
            CameraUIBadgeOverlay(camera: camera)
        }
        .overlay(alignment: .bottom, content: {
            SpeechTranscriptionView()
        })
        .overlay(alignment: .bottomLeading, content: {
            ActiveListeningButton(camera: camera)
                .padding([.leading, .bottom])
        })
        .overlay(alignment: .bottomTrailing, content: {
            ShowAboutButton()
                .buttonStyle(DefaultButtonStyle(size: .large))
                .padding([.trailing, .bottom])
        })
        .overlay {
            llmResponseUI
        }
        .padding(.trailing)
    }
    
    @ViewBuilder
    var llmResponseUI: some View {
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
            .onChange(of: modelResponse, initial: true) { _, newValue in
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    if modelController.modelResponse == newValue {
                        modelController.modelResponse = nil
                    }
                }
            }
        }
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
        let rect = AVMakeRect(aspectRatio: AspectRatio.movie.cgSize, insideRect: uiRect)
        let padding = (rect.minY.rounded() / 2) + 12
        return padding
    }
}

#if DEBUG
#Preview {
    @Previewable @State var toolUIManager = ToolEnabledUIManager()
    
    _CameraUIPreview(toolUIManager: toolUIManager)
        .environment(toolUIManager)
        .environmentObject(SpeechRecognizer())
}

/// A private struct only for previews designed to help manage one ``ToolEnabledUIManager`` in descendents
private struct _CameraUIPreview: View {
    @State var model: VoiceActivatedFMController<PreviewCameraModel>
    
    init(toolUIManager: ToolEnabledUIManager) {
        self.model = VoiceActivatedFMController<PreviewCameraModel>(camera: PreviewCameraModel(), toolUIManager: toolUIManager)
    }
    
    var body: some View {
        CameraUI(camera: PreviewCameraModel(), swipeDirection: .constant(.left))
            .environment(model)
    }
}
#endif
