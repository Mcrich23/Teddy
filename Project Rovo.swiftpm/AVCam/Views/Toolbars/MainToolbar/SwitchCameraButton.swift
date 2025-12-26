/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a button to switch between available cameras.
*/

import SwiftUI

/// A view that displays a button to switch between available cameras.
struct SwitchCameraButton<CameraModel: Camera>: View {
    @Environment(ToolEnabledUIManager.self) var toolUIManager
    @State var camera: CameraModel
    
    var body: some View {
        Button {
            Task {
                try await camera.switchVideoDevices()
            }
            withAnimation(.bouncy) {
                toolUIManager.flipCamera()
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .rotationEffect(.degrees(toolUIManager.cameraFlipRotation))
        }
        .frame(width: largeButtonSize.width, height: largeButtonSize.height)
        .disabled(camera.captureActivity.isRecording)
        .allowsHitTesting(!camera.isSwitchingVideoDevices)
    }
}
