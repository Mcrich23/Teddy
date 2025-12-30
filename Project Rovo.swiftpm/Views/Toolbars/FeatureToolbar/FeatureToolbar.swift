/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents controls to enable capture features.
*/

import SwiftUI

/// A view that presents controls to enable capture features.
struct FeaturesToolbar<CameraModel: Camera, DismissRectangle: View>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.orientation) var orientation
    
    @State var camera: CameraModel
    
    /// Hides flash menu if other area is tapped
    @ViewBuilder
    var dismissFlashMenuRectangle: DismissRectangle
    
    init(camera: CameraModel, isShowingFlashMenu: Binding<Bool>, dismissFlashMenuRectangle: DismissRectangle) {
        self.camera = camera
        self.dismissFlashMenuRectangle = dismissFlashMenuRectangle
        self._isShowingFlashMenu = isShowingFlashMenu
    }
    
    init(camera: CameraModel, isShowingFlashMenu: Binding<Bool>, @ViewBuilder dismissFlashMenuRectangle: () -> DismissRectangle) {
        self.camera = camera
        self.dismissFlashMenuRectangle = dismissFlashMenuRectangle()
        self._isShowingFlashMenu = isShowingFlashMenu
    }
    
    var body: some View {
        if isCompactSize {
            internalBody
                .frame(height: 30)
                .padding(.horizontal)
            // Hide the toolbar items when a person interacts with capture controls.
                .overlay(alignment: .center) {
                    if orientation.isPortrait {
                        CameraUIBadgeOverlay(camera: camera)
                            .animation(.default, value: orientation)
                    }
                }
        } else {
            internalBody
        }
    }
    
    var internalBody: some View {
        DeviceVHStack(spacing: 30) {
            if camera.isFlashAvailable {
                flashMenu
                    .overlay {
                        if camera.isPrecisionZooming {
                            dismissFlashMenuRectangle
                        }
                    }
            }
            Group {
                if horizontalSizeClass == .compact {
                    ActiveListeningButton(camera: camera)
                    Spacer()
                }
                
                if camera.isLivePhotoAvailable {
                    livePhotoButton
                }
//              prioritizePicker
                if camera.isHDRVideoSupported {
                    hdrButton
                }
            }
            .allowsHitTesting(!isShowingFlashMenu)
            .overlay {
                dismissFlashMenuRectangle
            }
        }
        .opacity(camera.prefersMinimizedUI ? 0 : 1)
        .buttonStyle(DefaultButtonStyle(size: isRegularSize ? .large : .small))
        .background(dismissFlashMenuRectangle)
    }
    
    ///  A button to toggle the enabled state of Live Photo capture.
    var livePhotoButton: some View {
        Button {
            camera.isLivePhotoEnabled.toggle()
        } label: {
            Image(systemName: camera.isLivePhotoEnabled ? "livephoto" : "livephoto.slash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                .animation(.default, value: camera.isLivePhotoEnabled)
                .frame(width: 30, height: 30)
        }
    }
    
    @ViewBuilder
    var prioritizePicker: some View {
        Menu {
            Picker("Quality Prioritization", selection: $camera.qualityPrioritization) {
                ForEach(QualityPrioritization.allCases) {
                    Text($0.description)
                        .font(.body.weight(.bold))
                }
            }
        } label: {
            Group {
                switch camera.qualityPrioritization {
                case .speed:
                    Image(systemName: "dial.low")
                case .balanced:
                    Image(systemName: "dial.medium")
                case .quality:
                    Image(systemName: "dial.high")
                }
            }
            .frame(width: 30, height: 30)
        }
    }

    @ViewBuilder
    var hdrButton: some View {
        Button {
            camera.isHDRVideoEnabled.toggle()
        } label: {
            ZStack {
                Text("HDR")
                    .font(.footnote.weight(.semibold))
                Image(systemName: camera.isHDRVideoEnabled ? "circle" : "circle.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(!camera.isHDRVideoEnabled ? .white : .clear, .clear)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    .allowsHitTesting(false)
            }
                .frame(width: 30, height: 30)
        }
        .animation(.default, value: camera.isHDRVideoEnabled)
        .disabled(camera.captureActivity.isRecording)
    }
    
    @ViewBuilder
    var compactSpacer: some View {
        if !isRegularSize {
            Spacer()
        }
    }
    
    // MARK: Flash
    var unpickedFlashModes: [FlashMode] { FlashMode.allCases.filter({ $0 != camera.flashMode }) }
    @Binding var isShowingFlashMenu: Bool
    @State var isShowingFlashMenuDict: [FlashMode : Bool] = [:]
    func resetFlashMenuDict() {
        isShowingFlashMenuDict.removeAll()
        
        for mode in unpickedFlashModes {
            isShowingFlashMenuDict[mode] = false
        }
    }
    func showFlashMenu() {
        for (i, mode) in unpickedFlashModes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100*i)) {
                withAnimation(.smooth) {
                    isShowingFlashMenuDict[mode] = true
                }
            }
        }
    }
    func hideFlashMenu() {
        for (i, mode) in unpickedFlashModes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100*i)) {
                withAnimation(.smooth) {
                    isShowingFlashMenuDict[mode] = false
                }
            }
        }
    }
    
    func flashSymbol(_ mode: FlashMode) -> String {
        switch mode {
        case .off:
            "bolt.slash"
        case .auto:
            "bolt.badge.automatic"
        case .on:
            "bolt"
        @unknown default:
            "bolt"
        }
    }
    
    @ViewBuilder
    var flashMenu: some View {
        ZStack {
            ForEach(unpickedFlashModes, id: \.self) { mode in
                if let index = FlashMode.allCases.filter({ $0 != camera.flashMode }).firstIndex(of: mode) {
                    if horizontalSizeClass == .compact {
                        flashMenuButton(mode)
                            .offset(y: CGFloat(isShowingFlashMenuDict[mode] == true ? (60 + (60*index)) : 0))
                    } else {
                        flashMenuButton(mode)
                            .offset(x: CGFloat(isShowingFlashMenuDict[mode] == true ? -(70 + (70*index)) : 0))
                    }
                }
            }
            Button {
                withAnimation(.smooth) {
                    isShowingFlashMenu.toggle()
                }
            } label: {
                Image(systemName: flashSymbol(camera.flashMode))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
            }
            .foregroundStyle(Color.white)
            .opacity(isShowingFlashMenu ? 0.5 : 1)
            .accessibilityLabel(Text(camera.flashMode.accessibilityLabel))
        }
        .onChange(of: isShowingFlashMenu) { _, newValue in
            if newValue {
                showFlashMenu()
            } else {
                hideFlashMenu()
            }
        }
    }
    
    func flashMenuButton(_ mode: FlashMode) -> some View {
        Button {
            withAnimation(.smooth) {
                isShowingFlashMenu = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50*unpickedFlashModes.count)) {
                self.camera.flashMode = mode
            }
        } label: {
            Image(systemName: flashSymbol(mode))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
        }
        .foregroundStyle(isShowingFlashMenuDict[mode] == true ? Color.white : .clear)
        .scaleEffect(isShowingFlashMenuDict[mode] == true ? 1 : 0)
        .allowsHitTesting(isShowingFlashMenuDict[mode] == true)
        .materialOpacity(0.7)
    }
}

///  A button to toggle the enabled state of LLM active listening
struct ActiveListeningButton<CameraModel: Camera>: PlatformView {
    let camera: CameraModel
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(ToolEnabledUIManager.self) var toolUIManager
    
    var isEnabled: Bool {
        toolUIManager.isActiveListening && !camera.captureActivity.isRecording
    }
    
    var body: some View {
        Button {
            toolUIManager.setActiveListening(!toolUIManager.isActiveListening)
        } label: {
            ZStack {
                Text("\(Image(systemName: "microphone"))R")
                    .font(.callout.weight(.semibold))
                Image(systemName: isEnabled ? "circle" : "circle.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(!isEnabled ? .white : .clear, .clear)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    .allowsHitTesting(false)
            }
                .frame(width: 30, height: 30)
        }
        .accessibilityLabel(Text(isEnabled ? "Disable Active Listening" : "Enable Active Listening"))
        .opacity(camera.prefersMinimizedUI ? 0 : 1)
        .buttonStyle(DefaultButtonStyle(size: isRegularSize ? .large : .small))
        .disabled(camera.captureActivity.isRecording)
    }
}
