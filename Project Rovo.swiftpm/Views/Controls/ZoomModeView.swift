/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents controls to enable capture features.
*/

import SwiftUI

// MARK: – ZoomModeModel

@Observable
@MainActor
private final class ZoomModeModel<CameraModel: Camera> {
    let camera: CameraModel
    
    init(camera: CameraModel) {
        self.camera = camera
    }
    
    var zoom: ZoomFactor?
    var zoomRange: [ZoomFactor] {
        var array: [ZoomFactor] = []
        
        if camera.zoomFactors.minZoom.value <= 1 {
            array.append(camera.zoomFactors.minZoom)
        }
        for factor in Int(camera.zoomFactors.minZoom.value)..<Int(camera.zoomFactors.maxZoom.value) {
            array.append(ZoomFactor(integerLiteral: factor+1))
        }
        return array
    }
    
    func id(for value: ZoomFactor, adding i: Int) -> ZoomFactor {
        if value < 1 {
            return value+ZoomFactor((Float(i)*0.1))
        } else {
            return value+ZoomFactor((Float(i)*0.2))
        }
    }
    
    func isActive(value: ZoomFactor) -> Bool {
        let zoom = self.zoom ?? camera.currentZoom
        
        return getZoomedValue(value) == zoom
    }
    
    func getZoomedValue(_ value: ZoomFactor) -> ZoomFactor {
        let zoom = self.zoom ?? camera.currentZoom
        
        guard !camera.zoomFactors.contains(zoom) else {
            return value
        }
        
        let closestValue = camera.zoomFactors.enumerated().filter({ $0.element < zoom }).sorted(by: <).last
        guard let closestValue, let factorIndex = camera.zoomFactors.firstIndex(of: value), closestValue.element >= value, ((closestValue.offset == camera.zoomFactors.count - 1 && value == camera.zoomFactors.last) || closestValue.element < camera.zoomFactors[factorIndex + 1]) else {
            return value
        }
        
        return zoom
    }
    
    func stringForValue(_ value: ZoomFactor) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2

        return numberFormatter.string(from: value.value as NSNumber)
    }
}

// MARK: – ZoomModeView

/// A view that presents controls to enable capture features.
struct ZoomModeView<CameraModel: Camera>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.materialOpacity) var materialOpacity
    
    @State private var model: ZoomModeModel<CameraModel>
    
    init(camera: CameraModel) {
        self.model = ZoomModeModel(camera: camera)
    }
    
    var body: some View {
        
//        GeometryReader { geo in
        Group {
            if horizontalSizeClass == .compact {
                CompactUI<CameraModel>()
            } else {
                RegularUI<CameraModel>()
            }
        }
        .buttonStyle(DefaultButtonStyle(size: .large))
        .materialOpacity(0.8)
        .padding()
        .background(
            Capsule()
                .fill(.black.opacity(0.3))
        )
        .onChange(of: model.camera.currentZoom, { _, newValue in
            guard newValue != model.camera.currentZoom else { return }
            self.model.zoom = newValue
        })
        .onChange(of: model.camera.isPrecisionZooming) { _, newValue in
            self.model.zoom = !newValue ? nil : model.camera.currentZoom
        }
        .onChange(of: model.zoom) { _, newValue in
            guard let newValue else { return }
            self.model.camera.setZoom(to: newValue)
        }
        .padding(.horizontal)
        // Hide the toolbar items when a person interacts with capture controls.
        .opacity(model.camera.prefersMinimizedUI ? 0 : 1)
        .environment(model)
    }
}

// MARK: – ZoomButton

private struct ZoomButton<CameraModel: Camera>: View {
    let value: ZoomFactor
    init(_ value: ZoomFactor) {
        self.value = value
    }
    
    @Environment(ZoomModeModel<CameraModel>.self) var model
    
    var body: some View {
        if let stringForValue = model.stringForValue(model.getZoomedValue(value)) {
            Button {
                if model.camera.currentZoom == value {
                    withAnimation(.bouncy) {
                        model.camera.isPrecisionZooming.toggle()
                    }
                } else {
                    withAnimation(.bouncy) {
                        model.camera.isPrecisionZooming = false
                    }
                    model.camera.animateZoom(to: value)
                }
            } label: {
                Text("\(stringForValue)")
                    .minimumScaleFactor(0.4)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(model.camera.currentZoom == model.getZoomedValue(value) ? Color.accentColor : .white)
            }
            .scaleEffect(model.isActive(value: value) ? 1 : 0.8)
        }
    }
}

// MARK: – CompactUI

private struct CompactUI<CameraModel: Camera>: View {
    @Environment(ZoomModeModel<CameraModel>.self) var model
    @State var width: CGFloat = 0
    
    var body: some View {
        @Bindable var model = model
        
        VStack {
            if model.camera.isPrecisionZooming {
                ScrollView(.horizontal) {
                    HStack(spacing: 5) {
                        Color.clear
                            .frame(width: width/2)
                            .id(model.zoomRange.first)
                        ForEach(model.zoomRange, id: \.self) { zoomFactor in
                            if zoomFactor == model.zoomRange.last, let stringForValue = model.stringForValue(zoomFactor) {
                                VStack(spacing: 0) {
                                    Rectangle()
                                        .fill(model.id(for: zoomFactor, adding: 0) == model.zoom ? Color.accentColor : .white)
                                        .frame(width: 2, height: 15)
                                        .padding(.bottom, 3)
                                    Spacer()
                                        .frame(width: 2, height: 15)
                                        .overlay {
                                            Text(stringForValue)
                                                .minimumScaleFactor(0.6)
                                                .frame(height: 15)
                                                .fixedSize()
                                        }
                                }
                                .foregroundStyle(model.id(for: zoomFactor, adding: 0) == model.zoom ? Color.accentColor : .white)
                                .id(model.id(for: zoomFactor, adding: 0))
                            } else {
                                ForEach(0..<5) { i in
                                    VStack(spacing: 0) {
                                        Rectangle()
                                            .fill(model.id(for: zoomFactor, adding: i) == model.zoom ? Color.accentColor : .white)
                                            .frame(width: 2, height: i == 0 ? 15 : 7)
                                            .padding(.bottom, 3)
                                        Spacer()
                                            .frame(width: 2, height: 15)
                                            .overlay {
                                                if i == 0, let stringForValue = model.stringForValue(zoomFactor) {
                                                    Text(stringForValue)
                                                        .minimumScaleFactor(0.6)
                                                        .frame(height: 15)
                                                        .fixedSize()
                                                }
                                            }
                                    }
                                    .foregroundStyle(model.id(for: zoomFactor, adding: i) == model.zoom ? Color.accentColor : .white)
                                    .id(model.id(for: zoomFactor, adding: i))
                                }
                            }
                        }
                        Color.clear
                            .frame(width: width/2)
                            .id(model.zoomRange.last)
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                //        .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $model.zoom, anchor: .center)
            } else {
                HStack(spacing: 30) {
                    ForEach(model.camera.zoomFactors, id: \.self) { factor in
                        ZoomButton<CameraModel>(factor)
                    }
                }
            }
        }
        .frame(height: 30)
        .onGeometryChange(for: CGSize.self, of: { proxy in
            proxy.size
        }, action: { newValue in
            self.width = newValue.width
        })
    }
}

// MARK: – RegularUI

private struct RegularUI<CameraModel: Camera>: View {
    @Environment(ZoomModeModel<CameraModel>.self) var model
    @State var height: CGFloat = 0
    
    var body: some View {
        @Bindable var model = model
        
        VStack {
            if model.camera.isPrecisionZooming {
                ScrollView(.vertical) {
                    VStack(spacing: 5) {
                        Color.clear
                            .frame(height: height/2)
                            .id(model.zoomRange.first)
                        ForEach(model.zoomRange, id: \.self) { zoomFactor in
                            if zoomFactor == model.zoomRange.last, let stringForValue = model.stringForValue(zoomFactor) {
                                VStack(spacing: 0) {
                                    Rectangle()
                                        .fill(model.id(for: zoomFactor, adding: 0) == model.zoom ? Color.accentColor : .white)
                                        .frame(width: 15, height: 2)
                                        .padding(.bottom, 3)
                                        .overlay(alignment: .trailing) {
                                            Text(stringForValue)
                                                .minimumScaleFactor(0.6)
                                                .frame(height: 15)
                                                .fixedSize()
                                                .offset(x: 10, y: -3)
                                        }
                                    Spacer()
                                        .frame(width: 15, height: 2)
                                }
                                .foregroundStyle(model.id(for: zoomFactor, adding: 0) == model.zoom ? Color.accentColor : .white)
                                .id(model.id(for: zoomFactor, adding: 0))
                            } else {
                                ForEach(0..<5) { i in
                                    VStack(spacing: 0) {
                                        Rectangle()
                                            .fill(model.id(for: zoomFactor, adding: i) == model.zoom ? Color.accentColor : .white)
                                            .frame(width: i == 0 ? 15 : 7, height: 2)
                                            .padding(.bottom, 3)
                                            .overlay(alignment: .trailing) {
                                                if i == 0, let stringForValue = model.stringForValue(zoomFactor) {
                                                    Text(stringForValue)
                                                        .minimumScaleFactor(0.6)
                                                        .frame(height: 15)
                                                        .fixedSize()
                                                        .offset(x: 10, y: -3)
                                                }
                                            }
                                        Spacer()
                                            .frame(width: 15, height: 2)
                                    }
                                    .foregroundStyle(model.id(for: zoomFactor, adding: i) == model.zoom ? Color.accentColor : .white)
                                    .id(model.id(for: zoomFactor, adding: i))
                                }
                            }
                        }
                        Color.clear
                            .frame(height: height/2)
                            .id(model.zoomRange.last)
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                //        .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $model.zoom, anchor: .center)
                .frame(maxHeight: 300)
            } else {
                VStack(spacing: 30) {
                    ForEach(model.camera.zoomFactors, id: \.self) { factor in
                        ZoomButton<CameraModel>(factor)
                    }
                }
            }
        }
        .frame(width: 40)
        .onGeometryChange(for: CGSize.self, of: { proxy in
            proxy.size
        }, action: { newValue in
            self.height = newValue.height
        })
    }
}

#Preview {
    @Previewable @State var swipeDirection = SwipeDirection.left
    CameraUI(camera: PreviewCameraModel(), swipeDirection: $swipeDirection)
}
