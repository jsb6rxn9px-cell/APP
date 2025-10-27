//
//  CountdownView.swift
//  GaitBAC
//

import SwiftUI

struct CountdownView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var app: AppState
    let meta: SessionMeta

    @State private var counter = 3
    @State private var goDate = Date()
    @State private var showRecording = false
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            Text("Get ready…").font(.headline)
            Text("\(max(0, counter))").font(.system(size: 96, weight: .black, design: .rounded))
            Text("Place the phone (\(meta.position.rawValue)). Stay still until GO.")
                .multilineTextAlignment(.center).padding()
            Button("Cancel", role: .cancel) {
                timer?.invalidate(); timer = nil
                dismiss()
            }
        }
        .onAppear {
            app.recorder.prepare(
                targetHz: meta.sampling_hz_target,
                durationSec: 0,
                prerollSec: 0,
                beeps: app.settings.beeps,
                haptics: false
            )
            if app.settings.beeps { AudioManager.activateSession() }
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate(); timer = nil
            AudioManager.deactivateSession()
        }
        .fullScreenCover(isPresented: $showRecording) {
            RecordingView(meta: meta, goDate: goDate).environmentObject(app)
        }
    }

    private func startCountdown() {
        counter = 3
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if counter > 0 {
                if app.settings.beeps { AudioManager.beepShort() }
                counter -= 1
            } else {
                if app.settings.beeps { AudioManager.beepLongGo() }
                goDate = Date()
                app.recorder.startRecording(withGoAt: goDate)
                t.invalidate()
                showRecording = true
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
}
