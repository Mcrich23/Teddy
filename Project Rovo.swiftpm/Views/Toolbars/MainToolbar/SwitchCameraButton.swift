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
                // Reversed somehow makes it correct?
                ForEach(Array(camera.availableCameras.keys).ordered.reversed()) { position in
                    Button {
                        Task {
                            await withAnimation {
                                toolUIManager.flipCamera()
                            }
                            try await camera.switchVideoDevices(to: position)
                        }
                    } label: {
                        if camera.cameraPosition == position {
                            HStack {
                                Image(systemName: "checkmark")
                                Text(position.rawValue.capitalized)
                            }
                        } else {
                            Text(position.rawValue.capitalized)
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
            .accessibilityLabel(Text("Switch Camera"))
        }
    }
}
