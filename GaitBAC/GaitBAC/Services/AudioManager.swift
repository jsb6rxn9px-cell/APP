//
//  AudioManager.swift
//  GaitBAC
//

import Foundation
import AVFoundation
import AudioToolbox

enum AudioManager {
    static func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.duckOthers])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
    }
    static func deactivateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    // System sounds: short and long-enough, non-blocking
    static func beepShort()   { AudioServicesPlaySystemSound(1104) } // "Tock"
    static func beepLongGo()  { AudioServicesPlaySystemSound(1110) } // "Begin"
    static func beepEnd()     { AudioServicesPlaySystemSound(1057) } // "SMSReceived" (optional)
}
