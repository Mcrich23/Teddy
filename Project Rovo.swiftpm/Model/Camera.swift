/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A protocol that represents the model for the camera view.
*/

import SwiftUI
import AVFoundation

/// A protocol that represents the model for the camera view.
///
/// The AVFoundation camera APIs require running on a physical device. The app defines the model as a protocol to make it
/// simple to swap out the real camera for a test camera when previewing SwiftUI views.
@MainActor
protocol Camera: AnyObject, Sendable {
    
    /// Provides the current status of the camera.
    var status: CameraStatus { get }

    /// The camera's current activity state, which can be photo capture, movie capture, or idle.
    var captureActivity: CaptureActivity { get }

    /// The source of video content for a camera preview.
    var previewSource: PreviewSource { get }
    
    /// Starts the camera capture pipeline.
    func start() async

    /// The capture mode, which can be photo or video.
    var captureMode: CaptureMode { get set }
    
    /// A Boolean value that indicates whether the camera is currently switching capture modes.
    var isSwitchingModes: Bool { get }
    
    /// A Boolean value that indicates whether the camera prefers showing a minimized set of UI controls.
    var prefersMinimizedUI: Bool { get }

    /// Switches between video devices available on the host system.
    @discardableResult
    func switchVideoDevices() async throws -> AVCaptureDevice.DeviceType
    
    /// Switches between video devices available on the host system.
    @discardableResult
    func switchVideoDevices(to device: AVCaptureDevice?) async throws -> AVCaptureDevice.DeviceType
    
    /// A dictionary of all of the available cameras
    var availableCameras: [CameraPosition : AVCaptureDevice] { get }
    
    /// A Boolean value that indicates whether the camera is currently switching video devices.
    var isSwitchingVideoDevices: Bool { get }
    
    /// Performs a one-time automatic focus and exposure operation.
    func focusAndExpose(at point: CGPoint) async
    
    /// A Boolean value that indicates whether to capture Live Photos when capturing stills.
    var isLivePhotoEnabled: Bool { get set }
    
    /// An enum value that indicates the current flash mode.
    var flashMode: FlashMode { get set }
    
    /// A value that indicates how to balance the photo capture quality versus speed.
    var qualityPrioritization: QualityPrioritization { get set }
    
    /// Captures a photo and writes it to the user's photo library.
    func capturePhoto() async
    
    /// A Boolean value that indicates whether to show visual feedback when capture begins.
    var shouldFlashScreen: Bool { get }
    
    /// A Boolean that indicates whether the camera supports HDR video recording.
    var isHDRVideoSupported: Bool { get }
    
    /// A Boolean value that indicates whether camera enables HDR video recording.
    var isHDRVideoEnabled: Bool { get set }
    
    /// A Boolean that indicates whether the camera has flash available.
    var isFlashAvailable: Bool { get }
    
    /// A Boolean that indicates whether the camera has live photo capabilities and live is currently available.
    var isLivePhotoAvailable: Bool { get }
    
    /// A Floating value that indicates the current zoom.
    var currentZoom: ZoomFactor { get }
    
    /// Set the zooming to a factor
    func setZoom(to targetZoom: ZoomFactor)
    
    /// Animate the zooming to a factor
    func animateZoom(to targetZoom: ZoomFactor)
    
    /// A value to handle active precision zooming
    var isPrecisionZooming: Bool { get set }
    
    /// A Floating value that indicates the available zoom factors.
    var zoomFactors: [ZoomFactor] { get }
    
    /// Starts or stops recording a movie, and writes it to the user's photo library when complete.
    func toggleRecording() async
    
    /// A thumbnail image for the most recent photo or video capture.
    var thumbnail: CGImage? { get }
    
    /// An error if the camera encountered a problem.
    var error: Error? { get }
}
