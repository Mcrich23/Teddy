/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import os
import SwiftUI

@main
/// The AVCam app's main entry point.
struct ProjectRovoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Simulator doesn't support the AVFoundation capture APIs. Use the preview camera when running in Simulator.
    #if targetEnvironment(simulator)
    @State private var camera = PreviewCameraModel()
    #else
    @State private var camera = CameraModel()
    #endif
    
    // An indication of the scene's operational state.
    @Environment(\.scenePhase) var scenePhase
    @State var orientation = UIDevice.current.orientation
    @State var iconRotationAngle: CGFloat = 0
    
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            CameraView(camera: camera)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .task {
                    // Start the capture pipeline.
                    await camera.start()
                }
                // Monitor the scene phase. Synchronize the persistent state when
                // the camera is running and the app becomes active.
                .environment(\.orientation, orientation)
                .environment(\.iconRotationAngle, iconRotationAngle)
                .onRotate { orientation in
                    guard !orientation.isFlat else { return }
                    self.orientation = orientation
                    self.iconRotationAngle = EnvironmentValues.setIconRotationAngle(orientation, previousValue: iconRotationAngle)
                }
        }
    }
}

/// A global logger for the app.
let logger = Logger()
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask? //By default you want all your views to rotate freely

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let orientationLock = AppDelegate.orientationLock {
            return orientationLock
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }
}

extension View {
    @ViewBuilder
    func forceRotation(orientation: UIInterfaceOrientationMask) -> some View {
        modifier(ForceRotationViewModifier(orientation: orientation))
    }
}

struct ForceRotationViewModifier: ViewModifier {
    let orientation: UIInterfaceOrientationMask
    
    func body(content: Content) -> some View {
        content
        .onAppear() {
            AppDelegate.orientationLock = orientation
        }
        .onDisappear() {
            AppDelegate.orientationLock = nil
        }
    }
}
