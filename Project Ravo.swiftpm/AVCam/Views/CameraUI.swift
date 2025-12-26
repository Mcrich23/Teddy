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
            }
            .background(Color.black.opacity(0.3).padding(.top, bottomPadding/2).padding(.bottom, -bottomPadding))
            .overlay {
                dismissFlashMenuRectangle
            }
        }
    }
    
    /// This view arranges UI elements in a layered stack.
    @ViewBuilder
    var regularUI: some View {
        VStack {
            Spacer()
            ZStack {
                Group {
                    CaptureModeView(camera: camera, direction: $swipeDirection)
                        .offset(x: -250) // The vertical offset from center.
                    MainToolbar(camera: camera)
                }
                .overlay {
                    dismissFlashMenuRectangle
                }
                FeaturesToolbar(camera: camera, isShowingFlashMenu: $isShowingFlashMenu, dismissFlashMenuRectangle: dismissFlashMenuRectangle)
                        .frame(width: 250)
                        .offset(x: 250) // The vertical offset from center.
            }
            .frame(width: 740)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(12)
            .padding(.bottom, 32)
        }
        .overlay(alignment: .top) {
            CameraUIBadgeOverlay(camera: camera)
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
        let bounds = UIScreen.main.bounds
        let rect = AVMakeRect(aspectRatio: movieAspectRatio, insideRect: bounds)
        let padding = (rect.minY.rounded() / 2) + 12
        return padding
    }
}

#Preview {
    CameraUI(camera: PreviewCameraModel(), swipeDirection: .constant(.left))
}
