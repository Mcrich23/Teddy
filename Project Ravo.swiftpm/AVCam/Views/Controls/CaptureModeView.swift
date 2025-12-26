/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that toggles the camera's capture mode.
*/

import SwiftUI

/// A view that toggles the camera's capture mode.
struct CaptureModeView<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    @Binding private var direction: SwipeDirection
    @Environment(\.materialOpacity) var materialOpacity
    
    init(camera: CameraModel, direction: Binding<SwipeDirection>) {
        self.camera = camera
        _direction = direction
    }
    
    var body: some View {
        HStack(spacing: 30) {
            Button("Photo") {
                camera.captureMode = .photo
            }
            .foregroundStyle(camera.captureMode == .photo ? Color.accentColor : .white)
            
            
//            Button {
//                
//            } label: {
//                Label {
//                    Text("Expand")
//                } icon: {
//                    Image(systemName: "chevron.compact.up")
//                        .resizable()
//                        .frame(width: 20, height: 8)
//                }
//                    .labelStyle(.iconOnly)
//            }
//            .foregroundStyle(.white)
            
            Button("Video") {
                camera.captureMode = .video
            }
            .foregroundStyle(camera.captureMode == .video ? Color.accentColor : .white)
        }
        .padding()
        .background(
            Capsule()
                .strokeBorder(.white, lineWidth: 0.5)
                .fill(.ultraThinMaterial.opacity(materialOpacity))
                .shadow(radius: 2)
        )
        .disabled(camera.captureActivity.isRecording)
        .onChange(of: direction) { _, _ in
            let modes = CaptureMode.allCases
            let selectedIndex = modes.firstIndex(of: camera.captureMode) ?? -1
            // Increment the selected index when swiping right.
            let increment = direction == .right
            let newIndex = selectedIndex + (increment ? 1 : -1)
            
            guard newIndex >= 0, newIndex < modes.count else { return }
            camera.captureMode = modes[newIndex]
        }
        // Hide the capture mode view when a person interacts with capture controls.
        .opacity(camera.prefersMinimizedUI ? 0 : 1)
    }
}

#Preview {
    CaptureModeView(camera: PreviewCameraModel(), direction: .constant(.left))
}
