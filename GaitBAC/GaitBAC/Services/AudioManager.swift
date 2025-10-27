//
//  AudioManager.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation
import AVFoundation
import AudioToolbox

enum AudioManager {
    static func activateSession() {
        // Joue même en mode silencieux, baisse les autres apps pendant le bip
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
    }
    static func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // IDs système courts et audibles
    static func beepCount() { AudioServicesPlaySystemSound(1104) }  // "Tock"
    static func beepGo()    { AudioServicesPlaySystemSound(1110) }  // "Begin"
    static func beepEnd()   { AudioServicesPlaySystemSound(1057) }  // "SMSReceived"
}
