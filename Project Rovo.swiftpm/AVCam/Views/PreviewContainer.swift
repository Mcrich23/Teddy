/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that provides a container view around the camera preview.
*/

import SwiftUI

struct AspectRatio {
    let width: CGFloat
    let height: CGFloat
    
    var cgSize: CGSize { .init(width: width, height: height) }
    
    static let photo = AspectRatio(width: 3.0, height: 4.0)
    @MainActor static let movie = UIDevice.current.userInterfaceIdiom == .phone ? AspectRatio(width: 9.0, height: 16.0) : AspectRatio(width: 4, height: 3)
}

/// A view that provides a container view around the camera preview.
///
/// This view applies transition effects when changing capture modes or switching devices.
/// On a compact device size, the app also uses this view to offset the vertical position
/// of the camera preview to better fit the UI when in photo capture mode.
@MainActor
struct PreviewContainer<Content: View, CameraModel: Camera>: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    // State values for transition effects.
    @State private var blurRadius = CGFloat.zero
    
    // When running in photo capture mode on a compact device size, move the preview area
    // update by the offset amount so that it's better centered between the top and bottom bars.
    private let photoModeOffset = CGFloat(-44)
    private let content: Content
    
    init(camera: CameraModel, @ViewBuilder content: () -> Content) {
        self.camera = camera
        self.content = content()
    }
    
    var body: some View {
        if horizontalSizeClass == .compact {
            previewView
                .clipped()
            // Apply an appropriate aspect ratio based on the selected capture mode.
                .aspectRatio(aspectRatio.cgSize, contentMode: .fit)
                .offset(y: -15)
        } else {
            previewView
                .clipped()
            // Apply an appropriate aspect ratio based on the selected capture mode.
                .aspectRatio(aspectRatio.cgSize, contentMode: .fit)
        }
    }
    
    /// Attach animations to the camera preview.
    var previewView: some View {
        content
            .blur(radius: blurRadius, opaque: true)
            .onChange(of: camera.isSwitchingModes, updateBlurRadius(_:_:))
            .onChange(of: camera.isSwitchingVideoDevices, updateBlurRadius(_:_:))
    }
    
    func updateBlurRadius(_: Bool, _ isSwitching: Bool) {
        withAnimation {
            blurRadius = isSwitching ? 30 : 0
        }
    }
    
    var aspectRatio: AspectRatio {
        camera.captureMode == .photo ? AspectRatio.photo : AspectRatio.movie
    }
}
