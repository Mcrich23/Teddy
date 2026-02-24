/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents a video preview of the captured content.
*/

import SwiftUI
@preconcurrency import AVFoundation
import CoreImage

struct CameraPreview<CameraType: Camera>: View {
    private let camera: CameraType
    @State private var preferredSheetGlassColorScheme = PreferredSheetGlassColorSchemeKey.defaultValue
    @State private var imageTracker = ImageTracker()
    let timer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()
    
    init(camera: CameraType) {
        self.camera = camera
    }
    
    var body: some View {
        _CameraPreview(camera: camera, imageTracker: imageTracker)
            .preferredSheetGlassColorScheme(preferredSheetGlassColorScheme)
            .onReceive(timer) { _ in
                let image = imageTracker.image
                Task.detached { [image, preferredSheetGlassColorScheme] in
                    guard let image, image.glassColorScheme != preferredSheetGlassColorScheme else { return }
                    let colorScheme = image.glassColorScheme
                    await MainActor.run {
                        self.preferredSheetGlassColorScheme = colorScheme
                    }
                }
            }
    }
}

private struct _CameraPreview<CameraType: Camera>: UIViewControllerRepresentable {
    
    private let camera: CameraType
    private let imageTracker: ImageTracker
    
    init(camera: CameraType, imageTracker: ImageTracker) {
        self.camera = camera
        self.imageTracker = imageTracker
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        guard let camera = camera as? CameraModel else {
            let preview = SingleCameraPreviewViewController<CameraType>()
            preview.camera = camera
            return preview
        }
        
        let preview = DualCameraPreviewViewController()
        preview.camera = camera
        preview.imageTracker = imageTracker
        return preview
    }
    
    func updateUIViewController(_ previewView: UIViewController, context: Context) {
        // No-op.
    }
}

/// A class that presents the captured content.
///
/// This class owns the `AVCaptureVideoPreviewLayer` that presents the captured content.
///
class PreviewView: UIView, PreviewTarget {
    
    init() {
        super.init(frame: .zero)
#if targetEnvironment(simulator)
        // The capture APIs require running on a real device. If running
        // in Simulator, display a static image to represent the video feed.
        let imageView = UIImageView(frame: UIScreen.main.bounds)
        imageView.image = UIImage(named: "video_mode")
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)
#endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Use the preview layer as the view's backing layer.
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    nonisolated func setSession(_ session: AVCaptureSession) {
        // Connects the session with the preview layer, which allows the layer
        // to provide a live view of the captured content.
        Task { @MainActor in
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
}

/// A protocol that enables a preview source to connect to a preview target.
///
/// The app provides an instance of this type to the client tier so it can connect
/// the capture session to the `PreviewView` view. It uses these protocols
/// to prevent explicitly exposing the capture objects to the UI layer.
///
protocol PreviewSource: Sendable {
    // Connects a preview destination to this source.
    func connect(to target: PreviewTarget)
}

/// A protocol that passes the app's capture session to the `CameraPreview` view.
protocol PreviewTarget {
    // Sets the capture session on the destination.
    func setSession(_ session: AVCaptureSession)
}

/// The app's default `PreviewSource` implementation.
struct DefaultPreviewSource: PreviewSource {
    
    private let session: AVCaptureSession
    
    init(session: AVCaptureSession) {
        self.session = session
    }
    
    func connect(to target: PreviewTarget) {
        target.setSession(session)
    }
}


// MARK: - SingleCameraPreviewViewController
final class SingleCameraPreviewViewController<CameraModel: Camera>: UIViewController {
    var camera: CameraModel? = nil
    let cameraPreview = PreviewView()
    
    private var previewAspectRatio: CGSize {
        guard let camera else { return CGSize(width: 3, height: 4) }

        let base: CGSize =
            camera.captureMode == .photo
            ? CGSize(width: 4, height: 3)
            : CGSize(width: 16, height: 9)

        let isPortrait = view.bounds.height > view.bounds.width

        return isPortrait
            ? CGSize(width: base.height, height: base.width)
            : base
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        view.addSubview(cameraPreview)
        cameraPreview.frame = view.bounds
        
        camera?.previewSource.connect(to: cameraPreview)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Main preview (aspect-fit like SwiftUI)
        cameraPreview.frame = aspectFitRect(
            aspectRatio: previewAspectRatio,
            inside: view.bounds
        )
    }
}

// MARK: - DualCameraPreviewViewController
/// Tracks the current background image
@Observable
private final class ImageTracker {
    var image: UIImage?
}

/// Plays back the blurred image
private struct MirrorImage: View {
    @State var imageTracker: ImageTracker
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                if let image = imageTracker.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: geo.size.height/4, alignment: .top)
                        .clipped()
                        .blur(radius: 10)
                    Spacer()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: geo.size.height/4, alignment: .bottom)
                        .clipped()
                        .blur(radius: 10)
                }
            }
            .brightness(-0.2)
        }
    }
}

/// Displays a clear image preview with a mirror on the edges as well.
final class DualCameraPreviewViewController: UIViewController {
    var camera: CameraModel? = nil
    let cameraPreview = PreviewView()
    
    // MIRROR preview (frame-based)
    fileprivate var imageTracker = ImageTracker()
    private var mirrorView: _UIHostingView<MirrorImage>? = nil
    
    private let outputQueue = DispatchQueue.main//(label: "camera.frame.queue")
    
    private var previewAspectRatio: CGSize {
        guard let camera else { return CGSize(width: 3, height: 4) }

        let base: CGSize =
            camera.captureMode == .photo
            ? CGSize(width: 4, height: 3)
            : CGSize(width: 16, height: 9)

        let isPortrait = view.bounds.height > view.bounds.width

        return isPortrait
            ? CGSize(width: base.height, height: base.width)
            : base
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupMirrorView()
        view.addSubview(cameraPreview)

        camera?.previewSource.connect(to: cameraPreview)
        setupSession()
    }

    override func viewDidLayoutSubviews() {
        guard let mirrorView else { return }
        
        super.viewDidLayoutSubviews()

        let bounds = view.bounds

        // Background mirror (oversized)
        let scale: CGFloat = 1.1
        mirrorView.frame = bounds.insetBy(
            dx: -bounds.width * (scale - 1) / 2,
            dy: -bounds.height * (scale - 1) / 2
        )
        // Main preview (aspect-fit like SwiftUI)
        cameraPreview.frame = aspectFitRect(
            aspectRatio: previewAspectRatio,
            inside: bounds
        )
    }

    // MARK: - Setup

    private func setupSession() {
        guard let camera else {
            return
        }
        camera.connectPreviewViewController(self, queue: outputQueue)
    }

    private func setupMirrorView() {
        mirrorView = _UIHostingView(rootView: MirrorImage(imageTracker: imageTracker))
        guard let mirrorView else { return }
        
        mirrorView.contentMode = .scaleAspectFill
        mirrorView.clipsToBounds = true

        // Optional polish
        mirrorView.alpha = 0.85

        view.addSubview(mirrorView)
        self.present(UIHostingController(rootView: MirrorImage(imageTracker: imageTracker)), animated: true)
    }
}

private func aspectFitRect(
    aspectRatio: CGSize,
    inside bounds: CGRect
) -> CGRect {

    let targetAspect = aspectRatio.width / aspectRatio.height
    let boundsAspect = bounds.width / bounds.height

    var size: CGSize

    if boundsAspect > targetAspect {
        // Container is wider → constrain by height
        size = CGSize(
            width: bounds.height * targetAspect,
            height: bounds.height
        )
    } else {
        // Container is taller → constrain by width
        size = CGSize(
            width: bounds.width,
            height: bounds.width / targetAspect
        )
    }

    return CGRect(
        x: bounds.midX - size.width / 2,
        y: bounds.midY - size.height / 2,
        width: size.width,
        height: size.height
    )
}

extension DualCameraPreviewViewController: @MainActor AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }

        let orientation = imageOrientationForCurrentDevice()

        let image = UIImage(cgImage: cgImage, scale: 1, orientation: orientation)

        imageTracker.image = image
    }

    // MARK: - Orientation mapping

    private func imageOrientationForCurrentDevice() -> UIImage.Orientation {
        let isFrontCamera = camera?.cameraPosition == .front // adjust if your CameraModel differs

        return isFrontCamera ? .leftMirrored : .right
    }
}

// Based on https://gist.github.com/adamcichy/2d00c7a54009b4a9751ba513749c485e

extension CGImage {
    var brightness: Double {
        get {
            let imageData = self.dataProvider?.data
            let ptr = CFDataGetBytePtr(imageData)
            var x = 0
            var result: Double = 0
            for _ in 0..<self.height {
                for _ in 0..<self.width {
                    let r = ptr![0]
                    let g = ptr![1]
                    let b = ptr![2]
                    result += (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
                    x += 1
                }
            }
            let bright = result / Double (x)
            return bright
        }
    }
}
extension UIImage {
    var brightness: Double {
        get {
            return (self.cgImage?.brightness)!
        }
    }
    
    var isDark: Bool {
        brightness < 100
    }
    
    var glassColorScheme: ColorScheme {
        isDark ? .light : .dark
    }
}
