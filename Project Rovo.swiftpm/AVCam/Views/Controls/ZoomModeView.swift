/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents controls to enable capture features.
*/

import SwiftUI

/// A view that presents controls to enable capture features.
struct ZoomModeView<CameraModel: Camera>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.materialOpacity) var materialOpacity
    
    @State var camera: CameraModel
    @State var zoom: ZoomFactor? = nil
    @State var width: CGFloat = 0
    
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
        value+ZoomFactor((Float(i)*0.2))
    }
    
    var body: some View {
        
//        GeometryReader { geo in
        VStack {
            if camera.isPrecisionZooming {
                ScrollView(.horizontal) {
                    HStack(spacing: 5) {
                        Color.clear
                            .frame(width: width/2)
                            .id(zoomRange.first)
                        ForEach(zoomRange, id: \.self) { zoomFactor in
                            if zoomFactor == zoomRange.last, let stringForValue = stringForValue(zoomFactor) {
                                VStack(spacing: 0) {
                                    Rectangle()
                                        .fill(id(for: zoomFactor, adding: 0) == zoom ? Color.accentColor : .white)
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
                                .foregroundStyle(id(for: zoomFactor, adding: 0) == zoom ? Color.accentColor : .white)
                                .id(id(for: zoomFactor, adding: 0))
                            } else {
                                ForEach(0..<5) { i in
                                    VStack(spacing: 0) {
                                        Rectangle()
                                            .fill(id(for: zoomFactor, adding: i) == zoom ? Color.accentColor : .white)
                                            .frame(width: 2, height: i == 0 ? 15 : 7)
                                            .padding(.bottom, 3)
                                        Spacer()
                                            .frame(width: 2, height: 15)
                                            .overlay {
                                                if i == 0, let stringForValue = stringForValue(zoomFactor) {
                                                    Text(stringForValue)
                                                        .minimumScaleFactor(0.6)
                                                        .frame(height: 15)
                                                        .fixedSize()
                                                }
                                            }
                                    }
                                    .foregroundStyle(id(for: zoomFactor, adding: i) == zoom ? Color.accentColor : .white)
                                    .id(id(for: zoomFactor, adding: i))
                                }
                            }
                        }
                        Color.clear
                            .frame(width: width/2)
                            .id(zoomRange.last)
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                //        .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $zoom, anchor: .center)
            } else {
                HStack(spacing: 30) {
                    ForEach(camera.zoomFactors, id: \.self) { factor in
                        zoomButton(factor)
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
        .buttonStyle(DefaultButtonStyle(size: .large))
        .materialOpacity(0.8)
        .padding()
        .background(
            Capsule()
                .fill(.black.opacity(0.3))
        )
        .onChange(of: camera.currentZoom, { _, newValue in
            guard newValue != camera.currentZoom else { return }
            self.zoom = newValue
        })
        .onChange(of: camera.isPrecisionZooming) { _, newValue in
            self.zoom = !newValue ? nil : camera.currentZoom
        }
        .onChange(of: zoom) { _, newValue in
            guard let newValue else { return }
            self.camera.currentZoom = newValue
        }
        .padding([.leading, .trailing])
        // Hide the toolbar items when a person interacts with capture controls.
        .opacity(camera.prefersMinimizedUI ? 0 : 1)
    }
    
    @ViewBuilder
    func zoomButton(_ value: ZoomFactor) -> some View {
        if let stringForValue = stringForValue(getZoomedValue(value)) {
            Button {
                if camera.currentZoom == value {
                    withAnimation(.bouncy) {
                        camera.isPrecisionZooming.toggle()
                    }
                } else {
                    withAnimation(.bouncy) {
                        camera.isPrecisionZooming = false
                    }
                    camera.animateZoom(to: value)
                }
            } label: {
                Text("\(stringForValue)")
                    .minimumScaleFactor(0.4)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(camera.currentZoom == getZoomedValue(value) ? Color.accentColor : .white)
            }
            .scaleEffect(isActive(value: value) ? 1 : 0.8)
        }
    }
    
    func isActive(value: ZoomFactor) -> Bool {
        let zoom = self.zoom ?? camera.currentZoom
        
        guard !camera.zoomFactors.contains(zoom) else {
            return zoom == value
        }
        
        let closestValueIndex = camera.zoomFactors.enumerated().min { abs($0.element.value - zoom.value) < abs($1.element.value - zoom.value) }?.offset
        guard let closestValueIndex, let valueIndex = zoomRange.firstIndex(of: value), closestValueIndex == valueIndex else {
            return false
        }
        
        return true
    }
    
    func getZoomedValue(_ value: ZoomFactor) -> ZoomFactor {
        let zoom = self.zoom ?? camera.currentZoom
        
        guard !camera.zoomFactors.contains(zoom) else {
            return value
        }
        
        let closestValueIndex = camera.zoomFactors.enumerated().min { abs($0.element.value - zoom.value) < abs($1.element.value - zoom.value) }?.offset
        guard let closestValueIndex, let valueIndex = zoomRange.firstIndex(of: value), closestValueIndex == valueIndex else {
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
