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
        if camera.availableCameras.count < 2 {
            Spacer()
                .frame(width: largeButtonSize.width, height: largeButtonSize.height)
        } else {
            Button {
                Task {
                    try await camera.switchVideoDevices()
                }
                toolUIManager.flipCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .rotationEffect(.degrees(toolUIManager.cameraFlipRotation))
                    .animation(.bouncy, value: toolUIManager.cameraFlipRotation)
            }
            .frame(width: largeButtonSize.width, height: largeButtonSize.height)
            .disabled(camera.captureActivity.isRecording)
            .allowsHitTesting(!camera.isSwitchingVideoDevices)
        }
    }
}
