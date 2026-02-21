//
//  Sounds.swift
//  Teddy
//
//  Created by Morris Richman on 2/14/26.
//

import AVFoundation

/// - Warning: You MUST re-initialize the ``SpeechRecognizer`` audio session after each sound play. Failure to do so will break audio.
actor Sounds {
    private static let startListeningSoundURL = URL(filePath: "/System/Library/Audio/UISounds/LiveTranslationStart.caf")
    private static let cancelSoundURL = URL(filePath: "/System/Library/Audio/UISounds/jbl_cancel.caf")
    private static let finishActionSoundURL = URL(filePath: "/System/Library/Audio/UISounds/NFCCardComplete.caf")
    private static let errorSoundURL = URL(filePath: "/System/Library/Audio/UISounds/nano/MicUnmuteFail.caf")
    private static let countdownNumberSoundURL = URL(filePath: "/System/Library/Audio/UISounds/PINEnterDigit_AX.caf")
    private static let photoCaptureSoundURL = URL(filePath: "/System/Library/Audio/UISounds/photoShutter.caf")
    private static let startRecordingSoundURL = URL(filePath: "/System/Library/Audio/UISounds/begin_record.caf")
    private static let stopRecordingSoundURL = URL(filePath: "/System/Library/Audio/UISounds/end_record.caf")
    
    private var audioPlayer: AVAudioPlayer?
    
    private func play(_ url: URL) async throws {
        var err: Error?
        do {
            // Respect silent mode by temporarily setting the category to ambient.
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.currentTime = 0
            audioPlayer?.volume = 1
            audioPlayer?.play()
        } catch {
            err = error
        }
        
        while audioPlayer?.isPlaying == true {
            try? await Task.sleep(for: .milliseconds(1))
        }
        
        if let err {
            throw err
        }
    }
    
    func playStartListeningSound() async throws {
        try await play(Self.startListeningSoundURL)
    }
    
    func playCancelSound() async throws {
        try await play(Self.cancelSoundURL)
    }
    
    func playFinishActionSound() async throws {
        try await play(Self.finishActionSoundURL)
    }
    
    func playErrorSound() async throws {
        try await play(Self.errorSoundURL)
    }
    
    func playCountdownNumberSound() async throws {
        try await play(Self.countdownNumberSoundURL)
    }
    
    func playPhotoCaptureSound() async throws {
        try await play(Self.photoCaptureSoundURL)
    }
    
    func playStartRecordingSound() async throws {
        try await play(Self.startRecordingSoundURL)
    }
    
    func playStopRecordingSound() async throws {
        try await play(Self.stopRecordingSoundURL)
    }
}
