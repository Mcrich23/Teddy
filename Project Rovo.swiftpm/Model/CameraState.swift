/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that provides camera state to share between the app and the extension.
*/

import os
import Foundation

struct CameraState: Codable {
    
    var flashMode = FlashMode.auto
    
    /// A Boolean that indicates whether the camera has flash available.
    var isFlashAvailable = false
    
    /// A Boolean that indicates whether the camera has live photo capabilities and live is currently available.
    var isLivePhotoAvailable = false
    
    var isLivePhotoEnabled = true
    
    var qualityPrioritization = QualityPrioritization.quality
    
    var isVideoHDRSupported = true
    
    var isVideoHDREnabled = false
    
    var captureMode = CaptureMode.photo
}
