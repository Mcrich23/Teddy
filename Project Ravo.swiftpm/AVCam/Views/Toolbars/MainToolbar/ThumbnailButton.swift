/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a thumbnail of the last captured media.
*/

import SwiftUI
import PhotosUI

/// A view that displays a thumbnail of the last captured media.
///
/// Tapping the view opens the Photos picker.
struct ThumbnailButton<CameraModel: Camera>: View {
    
	@State var camera: CameraModel
    
    @State private var selectedItems: [PhotosPickerItem] = []
	
    var body: some View {
        Link(destination: URL(string: "photos-redirect://")!, label: {
            thumbnail
        })
		.frame(width: 64.0, height: 64.0)
		.cornerRadius(8)
        .disabled(camera.captureActivity.isRecording)
        .buttonStyle(.automatic)
    }
    
    @ViewBuilder
    var thumbnail: some View {
        if let thumbnail = camera.thumbnail {
            Image(thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .animation(.easeInOut(duration: 0.3), value: thumbnail)
        } else {
            Image(systemName: "photo.on.rectangle")
        }
    }
}
