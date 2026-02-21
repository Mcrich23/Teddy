//
//  CameraUIBadgeOverlay.swift
//  iOS19Camera
//
//  Created by Morris Richman on 3/21/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct CameraUIBadgeOverlay: PlatformView {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: Camera
    
    var body: some View {
        switch camera.captureMode {
        case .photo:
            EmptyView()
//            LiveBadge()
//                .opacity(camera.captureActivity.isLivePhoto ? 1.0 : 0.0)
        case .video:
            RecordingTimeView(time: camera.captureActivity.currentTime)
                .offset(y: isRegularSize ? 20 : 0)
        }
    }
}
