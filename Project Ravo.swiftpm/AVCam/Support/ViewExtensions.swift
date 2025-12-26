/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions and supporting SwiftUI types.
*/

import SwiftUI
import UIKit

let largeButtonSize = CGSize(width: 64, height: 64)
let smallButtonSize = CGSize(width: 32, height: 32)

@MainActor
protocol PlatformView: View {
    var verticalSizeClass: UserInterfaceSizeClass? { get }
    var horizontalSizeClass: UserInterfaceSizeClass? { get }
    var isRegularSize: Bool { get }
    var isCompactSize: Bool { get }
}

extension PlatformView {
    var isRegularSize: Bool { horizontalSizeClass == .regular && verticalSizeClass == .regular }
    var isCompactSize: Bool { horizontalSizeClass == .compact || verticalSizeClass == .compact }
}

/// A container view for the app's toolbars that lays the items out horizontally
/// on iPhone and vertically on iPad and Mac Catalyst.
struct AdaptiveToolbar<Content: View>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat
    private let content: Content
    
    init(horizontalSpacing: CGFloat = 0.0, verticalSpacing: CGFloat = 0.0, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    var body: some View {
        if isRegularSize {
            VStack(spacing: verticalSpacing) { content }
        } else {
            HStack(spacing: horizontalSpacing) { content }
        }
    }
}

struct DefaultButtonStyle: PrimitiveButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.iconRotationAngle) var iconRotationAngle
    @Environment(\.materialOpacity) var materialOpacity

    enum Size: CGFloat {
        case small = 22
        case large = 24
    }
    
    private let size: Size
    
    init(size: Size) {
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            configuration.label
                .foregroundStyle(isEnabled ? .primary : Color(white: 0.4))
                .font(.system(size: size.rawValue))
                // Pad buttons on devices that use the `regular` size class,
                // and also when explicitly requesting large buttons.
                .padding(isRegularSize || size == .large ? 10.0 : 5.0)
    //            .background(.black.opacity(0.4))
    //            .background(
    //                Circle()
    //                    .strokeBorder(.white, lineWidth: 0.5)
    //                    .fill(.ultraThinMaterial.opacity(materialOpacity))
    //                    .shadow(radius: 2)
    //            )
                .rotationEffect(.degrees(iconRotationAngle))
                .animation(.default, value: iconRotationAngle)
        }
        .buttonStyle(.glass)
        .environment(\.colorScheme, .dark)
        .buttonBorderShape(.circle)
    }
    
    var isRegularSize: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
}

extension View {
    func debugBorder(color: Color = .red) -> some View {
        self
            .border(color)
    }
    
    func materialOpacity(_ opacity: Double) -> some View {
        self.environment(\.materialOpacity, opacity)
    }
}

extension Image {
    init(_ image: CGImage) {
        self.init(uiImage: UIImage(cgImage: image))
    }
}

// Our custom view modifier to track rotation and
// call our action
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

extension EnvironmentValues {
    @Entry var orientation: UIDeviceOrientation = .unknown
    @Entry var iconRotationAngle: CGFloat = setIconRotationAngle(.unknown, previousValue: 0)
    @Entry var materialOpacity: CGFloat = 0.3
    
    static func setIconRotationAngle(_ orientation: UIDeviceOrientation, previousValue: CGFloat) -> CGFloat {
        switch orientation {
        case .portrait:
            return 0
        case .portraitUpsideDown:
            return 0
        case .landscapeLeft:
            return 90
        case .landscapeRight:
            return -90
        default:
            return previousValue
        }
    }
}
