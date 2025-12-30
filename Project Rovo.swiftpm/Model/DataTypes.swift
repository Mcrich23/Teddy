/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Supporting data types for the app.
*/

import AVFoundation
import FoundationModels

// MARK: - Supporting types

/// An enumeration that describes the current status of the camera.
enum CameraStatus {
    /// The initial status upon creation.
    case unknown
    /// A status that indicates a person disallows access to the camera or microphone.
    case unauthorized
    /// A status that indicates the camera failed to start.
    case failed
    /// A status that indicates the camera is successfully running.
    case running
    /// A status that indicates higher-priority media processing is interrupting the camera.
    case interrupted
}

/// An enumeration that describes the current status of Flash
@Generable
enum FlashMode: CaseIterable, Codable {
    case off
    case on
    case auto
    
    var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off:
            return .off
        case .on:
            return .on
        case .auto:
            return .auto
        }
    }
    
    var avTorchMode: AVCaptureDevice.TorchMode {
        switch self {
        case .off:
            return .off
        case .on:
            return .on
        case .auto:
            return .auto
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .off:
            return "Flash Disabled"
        case .on:
            return "Flash Enabled"
        case .auto:
            return "Automatic Flash"
        }
    }
}

extension FlashMode {
    init(fromAV: AVCaptureDevice.FlashMode) {
        self = Self.allCases.first(where: { $0.avFlashMode == fromAV }) ?? .auto
    }
}

@Generable
struct ZoomFactor: Equatable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, Hashable, PromptRepresentable {
    var promptRepresentation: Prompt { value }
    
    var value: Float
    
    init(_ value: Float) {
        self.value = value
    }
    
    init(floatLiteral value: FloatLiteralType) {
        self.value = Float(value)
    }
    
    init(integerLiteral value: IntegerLiteralType) {
        self.value = Float(value)
    }
    
    // Equatable Function Overrides
    
    static func += (lhs: inout ZoomFactor, rhs: ZoomFactor) {
        lhs.value += rhs.value
    }
    
    static func -= (lhs: inout ZoomFactor, rhs: ZoomFactor) {
        lhs.value -= rhs.value
    }
    
    static func + (lhs: ZoomFactor, rhs: ZoomFactor) -> ZoomFactor {
        ZoomFactor(lhs.value + rhs.value)
    }
    
    static func - (lhs: ZoomFactor, rhs: ZoomFactor) -> ZoomFactor {
        ZoomFactor(lhs.value - rhs.value)
    }
}

extension ZoomFactor: Comparable {
    static func < (lhs: ZoomFactor, rhs: ZoomFactor) -> Bool {
        lhs.value < rhs.value
    }
    
    static func > (lhs: ZoomFactor, rhs: ZoomFactor) -> Bool {
        lhs.value > rhs.value
    }
    
    static func == (lhs: ZoomFactor, rhs: ZoomFactor) -> Bool {
        lhs.value == rhs.value
    }
}

extension [ZoomFactor] {
    /// A Floating value that indicates the maximum zoom factor
    var maxZoom: ZoomFactor {
        let sqr = ZoomFactor(pow(maxZoomFactor.value, 2))
        guard sqr > maxZoomFactor else { return 5 }
        return sqr
    }

    /// A Floating value that indicates the maximum zoom factor
    var maxZoomFactor: ZoomFactor { self.last ?? ZoomFactor(1) }

    /// A Floating value that indicates the minimum zoom factor
    var minZoom: ZoomFactor { self.first ?? ZoomFactor(1) }
}

/// An enumeration that defines the activity states the capture service supports.
///
/// This type provides feedback to the UI regarding the active status of the `CaptureService` actor.
enum CaptureActivity {
    case idle
    /// A status that indicates the capture service is performing photo capture.
    case photoCapture(willCapture: Bool = false, isLivePhoto: Bool = false)
    /// A status that indicates the capture service is performing movie capture.
    case movieCapture(duration: TimeInterval = 0.0)
    
    var isLivePhoto: Bool {
        if case .photoCapture(_, let isLivePhoto) = self {
            return isLivePhoto
        }
        return false
    }
    
    var willCapture: Bool {
        if case .photoCapture(let willCapture, _) = self {
            return willCapture
        }
        return false
    }
    
    var currentTime: TimeInterval {
        if case .movieCapture(let duration) = self {
            return duration
        }
        return .zero
    }
    
    var isRecording: Bool {
        if case .movieCapture(_) = self {
            return true
        }
        return false
    }
}

/// An enumeration of the capture modes that the camera supports.
@Generable
enum CaptureMode: String, Identifiable, CaseIterable, Codable {
    var id: Self { self }
    /// A mode that enables photo capture.
    case photo
    /// A mode that enables video capture.
    case video
    
    var systemName: String {
        switch self {
        case .photo:
            "camera.fill"
        case .video:
            "video.fill"
        }
    }
}

/// A structure that represents a captured photo.
struct Photo: Sendable {
    let data: Data
    let isProxy: Bool
    let livePhotoMovieURL: URL?
}

/// A structure that contains the uniform type identifier and movie URL.
struct Movie: Sendable {
    /// The temporary location of the file on disk.
    let url: URL
}

struct PhotoFeatures {
    let isLivePhotoEnabled: Bool
    let qualityPrioritization: QualityPrioritization
}

/// A structure that represents the capture capabilities of `CaptureService` in
/// its current configuration.
struct CaptureCapabilities {

    let isLivePhotoCaptureSupported: Bool
    let isHDRSupported: Bool
    let isFlashSupported: Bool
    
    init(isLivePhotoCaptureSupported: Bool = false,
         isHDRSupported: Bool = false,
         isFlashSupported: Bool = false) {
        self.isLivePhotoCaptureSupported = isLivePhotoCaptureSupported
        self.isHDRSupported = isHDRSupported
        self.isFlashSupported = isFlashSupported
    }
    
    static let unknown = CaptureCapabilities()
}

enum QualityPrioritization: Int, Identifiable, CaseIterable, CustomStringConvertible, Codable {
    var id: Self { self }
    case speed = 1
    case balanced
    case quality
    var description: String {
        switch self {
        case.speed:
            return "Speed"
        case .balanced:
            return "Balanced"
        case .quality:
            return "Quality"
        }
    }
}

enum CameraError: Error {
    case videoDeviceUnavailable
    case audioDeviceUnavailable
    case addInputFailed
    case addOutputFailed
    case setupFailed
    case deviceChangeFailed
}

protocol OutputService {
    associatedtype Output: AVCaptureOutput
    var output: Output { get }
    var captureActivity: CaptureActivity { get }
    var capabilities: CaptureCapabilities { get }
    func updateConfiguration(for device: AVCaptureDevice)
    func setVideoRotationAngle(_ angle: CGFloat)
}

extension OutputService {
    func setVideoRotationAngle(_ angle: CGFloat) {
        // Set the rotation angle on the output object's video connection.
        output.connection(with: .video)?.videoRotationAngle = angle
    }
    func updateConfiguration(for device: AVCaptureDevice) {}
}
