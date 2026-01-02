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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var captureMode: CaptureMode
    
    init(camera: CameraModel, direction: Binding<SwipeDirection>) {
        self.camera = camera
        _direction = direction
        captureMode = camera.captureMode
        
        UISegmentedControl.appearance().perform(NSSelectorFromString("_setUseGlass:"), with: true)
    }
    
    var body: some View {
        DeviceVHStack(spacing: 30) {
            Picker("Capture Mode", selection: $captureMode) {
                ForEach(CaptureMode.allCases) { mode in
                    Text(mode.rawValue.capitalized)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 200)
            
//            Button {
//                Task {
//                    await camera.setCaptureMode(.photo)
//                }
//            } label: {
//                Text("Photo")
//                    .padding(.top, horizontalSizeClass == .compact ? 0 : nil)
//                    .padding(.bottom, horizontalSizeClass == .compact ? 0 : 3)
//            }
//            .foregroundStyle(camera.captureMode == .photo ? Color.accentColor : .white)
//            
//            
////            Button {
////                
////            } label: {
////                Label {
////                    Text("Expand")
////                } icon: {
////                    Image(systemName: "chevron.compact.up")
////                        .resizable()
////                        .frame(width: 20, height: 8)
////                }
////                    .labelStyle(.iconOnly)
////            }
////            .foregroundStyle(.white)
//            
//            Button {
//                Task {
//                    await camera.setCaptureMode(.video)
//                }
//            } label: {
//                Text("Video")
//                    .padding(.bottom, horizontalSizeClass == .compact ? 0 : nil)
//                    .padding(.top, horizontalSizeClass == .compact ? 0 : 3)
//            }
//            .foregroundStyle(camera.captureMode == .video ? Color.accentColor : .white)
        }
//        .padding()
        .glassEffect(.regular.interactive(), in: .capsule)
        .disabled(camera.captureActivity.isRecording)
        .onChange(of: captureMode, { oldValue, newValue in
            guard camera.captureMode != newValue else { return }
            Task {
                await camera.setCaptureMode(newValue)
            }
        })
        .onChange(of: camera.captureMode) { oldValue, newValue in
            captureMode = newValue
        }
        .onChange(of: direction) { _, _ in
            let modes = CaptureMode.allCases
            let selectedIndex = modes.firstIndex(of: camera.captureMode) ?? -1
            // Increment the selected index when swiping right.
            let increment = direction == .right
            let newIndex = selectedIndex + (increment ? 1 : -1)
            
            guard newIndex >= 0, newIndex < modes.count else { return }
            Task {
                await camera.setCaptureMode(modes[newIndex])
            }
        }
        // Hide the capture mode view when a person interacts with capture controls.
        .opacity(camera.prefersMinimizedUI ? 0 : 1)
    }
}

#Preview {
    CaptureModeView(camera: PreviewCameraModel(), direction: .constant(.left))
}
