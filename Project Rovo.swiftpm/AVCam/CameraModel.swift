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
            // Synchronize the state of the model with the persistent state.
            await syncState()
            // Start the capture service to start the flow of data.
            try await captureService.start(with: cameraState)
            observeState()
            status = .running
        } catch {
            logger.error("Failed to start capture service. \(error)")
            status = .failed
        }
    }
    
    /// Synchronizes the persistent camera state.
    ///
    /// `CameraState` represents the persistent state, such as the capture mode, that the app and extension share.
    func syncState() async {
        cameraState = await CameraState.current
        captureMode = cameraState.captureMode
        qualityPrioritization = cameraState.qualityPrioritization
        isLivePhotoEnabled = cameraState.isLivePhotoEnabled
        isHDRVideoEnabled = cameraState.isVideoHDREnabled
    }
    
    // MARK: - Changing flash
    
    /// The current state of flash for capture
    var flashMode: FlashMode = .auto {
        didSet {
            guard status == .running else { return }
            Task {
                do {
                    try? await captureService.setFlashMode(flashMode)
                    cameraState.flashMode = flashMode
                } catch {
                    self.error = error
                }
            }
        }
    }
    
    // MARK: - Zooming
    
    /// A Floating value that indicates the zoom factor
    var currentZoom: ZoomFactor = 1.0 {
        didSet {
            guard status == .running else { return }
            Task {
                do {
                    try await captureService.setZoomFactor(currentZoom, animatedRate: nil)
                } catch {
                    self.error = error
                }
            }
        }
    }
    
    func animateZoom(to targetZoom: ZoomFactor) {
        guard status == .running else { return }
        Task {
            do {
                try await captureService.setZoomFactor(targetZoom, animatedRate: 300)
            } catch {
                self.error = error
            }
        }
    }
    
    var isPrecisionZooming: Bool = false {
        didSet {
            Task {
                do {
                    switch isPrecisionZooming {
                    case true: try await captureService.startPrecisionZooming()
                    case false: await captureService.stopPrecisionZooming()
                    }
                } catch {
                    self.error = error
                }
            }
        }
    }
    
    // MARK: - Changing modes and devices
    
    /// A value that indicates the mode of capture for the camera.
    var captureMode = CaptureMode.photo {
        didSet {
            guard status == .running else { return }
            Task {
                isSwitchingModes = true
                defer { isSwitchingModes = false }
                // Update the configuration of the capture service for the new mode.
                do {
                    try await captureService.setCaptureMode(captureMode)
                    
                    // Update the persistent state value.
                    cameraState.captureMode = captureMode
                } catch {
                    self.error = error
                }
            }
        }
    }
    
    /// Selects the next available video device for capture.
    func switchVideoDevices() async {
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        await captureService.selectNextVideoDevice()
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
    func focusAndExpose(at point: CGPoint) async {
        await captureService.focusAndExpose(at: point)
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
            Task {
                await captureService.setHDRVideoEnabled(isHDRVideoEnabled)
                // Update the persistent state value.
                cameraState.isVideoHDREnabled = isHDRVideoEnabled
            }
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
    
    // MARK: - Get Photos
    /// Fetches the last photo and sets ``thumbnail`` to said image.
    func fetchLastPhoto() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard let asset = fetchResult.firstObject else { return }
        let manager = PHImageManager.default()
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        manager.requestImage(for: asset,
                             targetSize: targetSize,
                             contentMode: .aspectFit,
                             options: nil,
                             resultHandler: { image, info in
            self.thumbnail = image?.cgImage
        })
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
            for await activity in await captureService.$captureActivity.values {
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
            for await capabilities in await captureService.$captureCapabilities.values {
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
            for await isShowingFullscreenControls in await captureService.$isShowingFullscreenControls.values {
                withAnimation {
                    // Prefer showing a minimized UI when capture controls enter a fullscreen appearance.
                    prefersMinimizedUI = isShowingFullscreenControls
                }
            }
        }
        
        Task {
            // Await updates to a camera zoom factor.
            for await currentZoom in await captureService.$currentZoom.values {
                withAnimation {
                    // Prefer showing a minimized UI when capture controls enter a fullscreen appearance.
                    self.currentZoom = currentZoom
                }
            }
        }
        
        Task {
            // Await updates to a camera max zoom factor.
            for await zoomFactors in await captureService.$zoomFactors.values {
                withAnimation {
                    // Prefer showing a minimized UI when capture controls enter a fullscreen appearance.
                    self.zoomFactors = zoomFactors
                }
            }
        }
        
        Task {
            // Await updates to a person's interaction with the Camera Control HUD.
            for await flashMode in await captureService.$flashMode.values {
                withAnimation {
                    // Prefer showing a minimized UI when capture controls enter a fullscreen appearance.
                    self.flashMode = flashMode
                }
            }
        }
    }
}
