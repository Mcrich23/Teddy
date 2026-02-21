/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that provides a container view around the camera preview.
*/

import SwiftUI

@MainActor
struct AspectRatio {
    let width: CGFloat
    let height: CGFloat
    
    var cgSize: CGSize { .init(width: width, height: height) }
    var portrait: AspectRatio {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .init(width: height, height: width)
        }
        
        return self
    }
    
    static let photo = UIDevice.current.userInterfaceIdiom == .phone ? AspectRatio(width: 3, height: 4) : AspectRatio(width: 4, height: 3)
    static let movie = UIDevice.current.userInterfaceIdiom == .phone ? AspectRatio(width: 9.0, height: 16.0) : AspectRatio(width: 16, height: 9)
}

/// A view that provides a container view around the camera preview.
///
/// This view applies transition effects when changing capture modes or switching devices.
/// On a compact device size, the app also uses this view to offset the vertical position
/// of the camera preview to better fit the UI when in photo capture mode.
@MainActor
struct PreviewContainer<Content: View, CameraModel: Camera>: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.orientation) var orientation
    
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
                .offset(y: -15)
        } else {
            previewView
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
        let aspectRatio = camera.captureMode == .photo ? AspectRatio.photo : AspectRatio.movie
        
        if orientation.isPortrait {
            return aspectRatio.portrait
        } else {
            return aspectRatio
        }
    }
}
