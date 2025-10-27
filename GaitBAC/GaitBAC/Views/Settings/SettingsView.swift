//
//  SettingsView.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @State private var soberCalibCount = 2

    var body: some View {
        Form {
            Section("Mesure") {
                Picker("Durée", selection: $app.settings.durationSec) {
                    Text("20 s").tag(20); Text("30 s").tag(30); Text("60 s").tag(60)
                }
                Picker("Fréquence cible", selection: $app.settings.targetHz) {
                    Text("60 Hz").tag(60); Text("100 Hz").tag(100); Text("200 Hz").tag(200)
                }
                Toggle("Bips", isOn: $app.settings.beeps)
                Toggle("Haptique", isOn: $app.settings.haptics)
            }
            Section("Fichiers & anonymisation") {
                TextField("Préfixe dossier", text: $app.settings.folderPrefix)
                Toggle("Anonymisation stricte (masque ID)", isOn: $app.settings.strictAnonymization)
            }
            Section("Calibration sobre") {
                Stepper("Essais: \(soberCalibCount)", value: $soberCalibCount, in: 2...3)
                Button("Lancer calibration") { let gen = UINotificationFeedbackGenerator(); gen.notificationOccurred(.success) }
            }
            Section("À propos") {
                Text("Schéma de fichier: v\(FILE_SCHEMA_VERSION)")
                Text("Version app: v\(APP_VERSION_STRING)")
            }
        }
        .navigationTitle("Réglages")
        .onDisappear { app.saveSettings() }
    }
}
