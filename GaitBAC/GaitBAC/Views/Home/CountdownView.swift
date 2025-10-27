//
//  CountdownView.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import SwiftUI

struct CountdownView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var app: AppState
    let meta: SessionMeta

    @State private var counter = 10
    @State private var goDate = Date()
    @State private var showRecording = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Préparation…").font(.headline)
            Text("\(counter)").font(.system(size: 96, weight: .black, design: .rounded))
            Text("Placez le téléphone (\(meta.position.rawValue)). Restez immobile jusqu’au GO.")
                .multilineTextAlignment(.center).padding()
            Button("Annuler", role: .cancel) { dismiss() }
        }
        .onAppear {
            app.recorder.prepare(
                targetHz: meta.sampling_hz_target,
                durationSec: meta.duration_target_s,
                prerollSec: meta.preroll_s,
                beeps: app.settings.beeps,
                haptics: app.settings.haptics
            )
            if app.settings.beeps { AudioManager.activateSession() }
            startCountdown()
        }
        .onDisappear { AudioManager.deactivateSession() }
        .onChange(of: counter) { _, newValue in
            if [3,2,1].contains(newValue) {
                if app.settings.haptics { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
                if app.settings.beeps { AudioManager.beepCount() }
            }
            if newValue == 0 {
                if app.settings.haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                if app.settings.beeps { AudioManager.beepGo() }
                goDate = Date()
                app.recorder.startRecording(withGoAt: goDate)
                showRecording = true
            }
        }
        .fullScreenCover(isPresented: $showRecording) {
            RecordingView(meta: meta, goDate: goDate).environmentObject(app)
        }
    }

    private func startCountdown() {
        counter = 10
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            counter -= 1
            if counter <= 0 { t.invalidate() }
        }
    }
}
