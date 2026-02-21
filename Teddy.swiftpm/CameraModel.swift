/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that provides the interface to the features of the camera.
*/

import SwiftUI
import Combine
import Photos

/// An object that provides the interface to the features of the camera.
///
/// This object provides the default implementation of the `Camera` protocol, which defines the interface
/// to configure the camera hardware and capture media. `CameraModel` doesn't perform capture itself, but is an
/// `@Observable` type that mediates interactions between the app's SwiftUI views and `CaptureService`.
///
/// For SwiftUI previews and Simulator, the app uses `PreviewCameraModel` instead.
///
@Observable
final class CameraModel: Camera {
    
    /// The current status of the camera, such as unauthorized, running, or failed.
    private(set) var status = CameraStatus.unknown
    
    /// The current state of photo or movie capture.
    private(set) var captureActivity = CaptureActivity.idle
    
    /// The currently selected camera position.
    private(set) var cameraPosition: CameraPosition = AVCaptureDevice.userPreferredCamera?.cameraPosition ?? .back
    
    /// A Boolean value that indicates whether the app is currently switching video devices.
    private(set) var isSwitchingVideoDevices = false
    
    /// A Boolean value that indicates whether the camera prefers showing a minimized set of UI controls.
    private(set) var prefersMinimizedUI = false
    
    /// A Boolean value that indicates whether the app is currently switching capture modes.
    private(set) var isSwitchingModes = false
    
    /// A Boolean value that indicates whether to show visual feedback when capture begins.
    private(set) var shouldFlashScreen = false
    
    /// A thumbnail for the last captured photo or video.
    private(set) var thumbnail: CGImage?
    
    /// An error that indicates the details of an error during photo or movie capture.
    private(set) var error: Error?
    
    /// An object that provides the connection between the capture session and the video preview layer.
    var previewSource: PreviewSource { captureService.previewSource }
    
    /// A Boolean that indicates whether the camera supports HDR video recording.
    private(set) var isHDRVideoSupported = false
    
    /// A Boolean that indicates whether the camera has flash available.
    private(set) var isFlashAvailable = false
    
    /// A Boolean that indicates whether the camera has live photo capabilities and live is currently available.
    private(set) var isLivePhotoAvailable = false
    
    /// A Floating value that indicates the current zoom.
    private(set) var zoomFactors: [ZoomFactor] = []
    
    /// An object that saves captured media to a person's Photos library.
    private let mediaLibrary = MediaLibrary()
    
    /// An object that manages the app's capture functionality.
    private let captureService = CaptureService()
    
    /// Persistent state shared between the app and capture extension.
    private var cameraState = CameraState()
    
    init() {
        //
    }
    
    // MARK: - Starting the camera
    /// Start the camera and begin the stream of data.
    func start() async {
        // Verify that the person authorizes the app to use device cameras and microphones.
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            // Start the capture service to start the flow of data.
            try await captureService.start(with: cameraState)
            observeState()
            status = .running
        } catch {
            logger.error("Failed to start capture service. \(error)")
            status = .failed
        }
    }
    
    /// Sets up Preview Layer output
    func connectPreviewViewController(_ previewViewController: DualCameraPreviewViewController, queue: DispatchQueue) {
        captureService.connectPreviewViewController(previewViewController, queue: queue)
    }
    
    // MARK: - Changing flash
    
    /// The current state of flash for capture
    var flashMode: FlashMode = .auto {
        didSet {
            guard status == .running else { return }
            do {
                try captureService.setFlashMode(flashMode)
                cameraState.flashMode = flashMode
            } catch {
                self.error = error
            }
        }
    }
    
    // MARK: - Zooming
    
    /// A Floating value that indicates the zoom factor
    private(set) var currentZoom: ZoomFactor = 1.0
    
    func setZoom(to targetZoom: ZoomFactor) {
        guard status == .running else { return }
        Task {
            do {
                try captureService.setZoomFactor(currentZoom, animatedRate: nil)
            } catch {
                self.error = error
            }
        }
        currentZoom = targetZoom
    }
    
    func animateZoom(to targetZoom: ZoomFactor) {
        guard status == .running else { return }
        Task {
            do {
                try captureService.setZoomFactor(targetZoom, animatedRate: 300)
            } catch {
                self.error = error
            }
        }
    }
    
    var isPrecisionZooming: Bool = false {
        didSet {
            do {
                switch isPrecisionZooming {
                case true: try captureService.startPrecisionZooming()
                case false: captureService.stopPrecisionZooming()
                }
            } catch {
                self.error = error
            }
        }
    }
    
    // MARK: - Changing modes and devices
    
    /// A value that indicates the mode of capture for the camera.
    private(set) var captureMode = CaptureMode.photo
    
    func setCaptureMode(_ mode: CaptureMode) async {
        captureMode = mode
        guard status == .running else { return }
        
        isSwitchingModes = true
        defer { isSwitchingModes = false }
        
        // Update the persistent state value.
        cameraState.captureMode = captureMode
        
        // Update the configuration of the capture service for the new mode.
        do {
            try captureService.setCaptureMode(captureMode)
        } catch {
            self.error = error
        }
    }
    
    /// Selects the next available video device for capture.
    func switchVideoDevices() async throws -> CameraPosition {
        try await switchVideoDevices(to: nil)
    }
    
    /// Selects the next available video device for capture.
    func switchVideoDevices(to position: CameraPosition? = nil) async throws -> CameraPosition {
        if let position, let device = availableCameras[position] {
            self.cameraPosition = position
            try captureService.changeCaptureDevice(to: device)
            return device.cameraPosition
        }
        
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        let position = try captureService.selectNextVideoDevice().cameraPosition
        
        self.cameraPosition = position
        return position
    }
    
    var availableCameras: [CameraPosition : AVCaptureDevice] {
        captureService.deviceLookup.cameras
    }
    
    // MARK: - Photo capture
    
    /// Captures a photo and writes it to the user's Photos library.
    func capturePhoto() async {
        do {
            let photoFeatures = PhotoFeatures(isLivePhotoEnabled: isLivePhotoEnabled, qualityPrioritization: qualityPrioritization)
            let photo = try await captureService.capturePhoto(with: photoFeatures)
            try await mediaLibrary.save(photo: photo)
        } catch {
            self.error = error
        }
    }
    
    /// A Boolean value that indicates whether to capture Live Photos when capturing stills.
    var isLivePhotoEnabled = true {
        didSet {
            // Update the persistent state value.
            cameraState.isLivePhotoEnabled = isLivePhotoEnabled
        }
    }
    
    /// A value that indicates how to balance the photo capture quality versus speed.
    var qualityPrioritization = QualityPrioritization.quality {
        didSet {
            // Update the persistent state value.
            cameraState.qualityPrioritization = qualityPrioritization
        }
    }
    
    /// Performs a focus and expose operation at the specified screen point.
    func focusAndExpose(at point: CGPoint) {
        captureService.focusAndExpose(at: point)
    }
    
    /// Sets the `showCaptureFeedback` state to indicate that capture is underway.
    private func flashScreen() {
        shouldFlashScreen = true
        withAnimation(.linear(duration: 0.01)) {
            shouldFlashScreen = false
        }
    }
    
    // MARK: - Video capture
    /// A Boolean value that indicates whether the camera captures video in HDR format.
    var isHDRVideoEnabled = false {
        didSet {
            guard status == .running, captureMode == .video else { return }
            captureService.setHDRVideoEnabled(isHDRVideoEnabled)
            // Update the persistent state value.
            cameraState.isVideoHDREnabled = isHDRVideoEnabled
        }
    }
    
    /// Toggles the state of recording.
    func toggleRecording() async {
        switch captureService.captureActivity {
        case .movieCapture:
            do {
                // If currently recording, stop the recording and write the movie to the library.
                let movie = try await captureService.stopRecording()
                try await mediaLibrary.save(movie: movie)
            } catch {
                self.error = error
            }
        default:
            // In any other case, start recording.
            do {
                try captureService.startRecording()
            } catch {
                self.error = error
            }
        }
    }
    
    // MARK: - Internal state observations
    
    // Set up camera's state observations.
    private func observeState() {
        Task {
            // Await new thumbnails that the media library generates when saving a file.
            for await thumbnail in mediaLibrary.thumbnails.compactMap({ $0 }) {
                self.thumbnail = thumbnail
            }
        }
        
        Task {
            // Await new capture activity values from the capture service.
            for await activity in captureService.$captureActivity.values {
                if activity.willCapture {
                    // Flash the screen to indicate capture is starting.
                    flashScreen()
                } else {
                    // Forward the activity to the UI.
                    captureActivity = activity
                }
            }
        }
        
        Task {
            // Await updates to the capabilities that the capture service advertises.
            for await capabilities in captureService.$captureCapabilities.values {
                // HDR Video
                isHDRVideoSupported = capabilities.isHDRSupported
                cameraState.isVideoHDRSupported = capabilities.isHDRSupported
                
                // Live Photo
                isLivePhotoAvailable = capabilities.isLivePhotoCaptureSupported
                cameraState.isLivePhotoAvailable = capabilities.isLivePhotoCaptureSupported
                
                // Flash
                isFlashAvailable = capabilities.isFlashSupported
                cameraState.isFlashAvailable = capabilities.isFlashSupported
            }
        }
        
        Task {
            // Await updates to a person's interaction with the Camera Control HUD.
            for await isShowingFullscreenControls in captureService.$isShowingFullscreenControls.values {
                await withAnimation {
                    // Prefer showing a minimized UI when capture controls enter a fullscreen appearance.
                    self.prefersMinimizedUI = isShowingFullscreenControls
                }
            }
        }
        
        Task {
            // Await updates to a camera zoom factor.
            while true {
                try? await Task.sleep(for: .milliseconds(100))
                guard currentZoom != captureService.currentZoom else { continue }
                await withAnimation {
                    // Prefer showing a minimized UI when capture controls enter a fullscreen appearance.
                    self.currentZoom = self.captureService.currentZoom
                }
            }
        }
        
        Task {
            // Await updates to a camera max zoom factor.
            for await zoomFactors in captureService.$zoomFactors.values {
                await withAnimation {
                    // Prefer showing a minimized UI when capture controls enter a fullscreen appearance.
                    self.zoomFactors = zoomFactors
                }
            }
        }
        
        Task {
            // Await updates to a person's interaction with the Camera Control HUD.
            for await flashMode in captureService.$flashMode.values {
                await withAnimation {
                    // Prefer showing a minimized UI when capture controls enter a fullscreen appearance.
                    self.flashMode = flashMode
                }
            }
        }
    }
}
