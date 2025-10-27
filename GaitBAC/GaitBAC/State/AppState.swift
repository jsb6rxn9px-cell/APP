//
//  AppState.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//
import Foundation
import SwiftUI

final class AppState: ObservableObject {
    @Published var settings = AppSettings()
    @Published var consentGranted: Bool = false
    @Published var sessions: [SessionRecord] = []

    let recorder = MotionRecorder()

    init() {
        loadSettings()
        loadSidecars()
    }

    func loadSettings() {
        let url = AppPaths.baseDir(prefix: settings.folderPrefix).appendingPathComponent("settings.json")
        if let data = try? Data(contentsOf: url),
           let s = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = s
        }
    }

    func saveSettings() {
        let url = AppPaths.baseDir(prefix: settings.folderPrefix).appendingPathComponent("settings.json")
        if let d = try? JSONEncoder().encode(settings) {
            try? d.write(to: url)
        }
    }
    func resetToConsent() {
        recorder.discard()          // efface sécurité l’état en cours
        consentGranted = false      // RootView affichera ConsentView
    }

    /// Efface juste la session en mémoire mais garde le consentement.
    func resetForRetake() {
        recorder.discard()
        // consentGranted reste true → retour à l’Accueil prêt à recommencer
    }
    func loadSidecars() {
        sessions.removeAll()
        let dir = AppPaths.sessionsDir(prefix: settings.folderPrefix)
        let urls = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for u in urls where u.pathExtension == "json" {
            if let d = try? Data(contentsOf: u),
               let rec = try? JSONDecoder().decode(SessionRecord.self, from: d) {
                sessions.append(rec)
            }
        }
        sessions.sort { $0.meta.session_id > $1.meta.session_id }
    
    }
}
