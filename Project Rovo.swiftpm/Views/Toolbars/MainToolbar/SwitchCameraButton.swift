/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a button to switch between available cameras.
*/

import SwiftUI

/// A view that displays a button to switch between available cameras.
struct SwitchCameraButton<CameraModel: Camera>: View {
    @Environment(ToolEnabledUIManager.self) var toolUIManager
    @Environment(\.iconRotationAngle) var iconRotationAngle
    @State var camera: CameraModel
    
    var body: some View {
        if camera.availableCameras.count < 2 {
            Spacer()
                .frame(width: largeButtonSize.width, height: largeButtonSize.height)
        } else {
            Menu {
                ForEach(Array(camera.availableCameras.keys)) { position in
                    Button(position.rawValue.capitalized) {
                        Task {
                            await withAnimation {
                                toolUIManager.flipCamera()
                            }
                            try await camera.switchVideoDevices(to: position)
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .rotationEffect(.degrees(toolUIManager.cameraFlipRotation))
                    .animation(.bouncy, value: toolUIManager.cameraFlipRotation)
                    .padding(10)
                    .rotationEffect(.degrees(UIDevice.current.userInterfaceIdiom == .phone ? iconRotationAngle : 0))
                    .animation(.default, value: iconRotationAngle)
            } primaryAction: {
                Task {
                    await withAnimation {
                        toolUIManager.flipCamera()
                    }
                    try await camera.switchVideoDevices()
                }
            }
            .frame(width: largeButtonSize.width, height: largeButtonSize.height)
            .disabled(camera.captureActivity.isRecording)
            .allowsHitTesting(!camera.isSwitchingVideoDevices)
        }
    }
}
