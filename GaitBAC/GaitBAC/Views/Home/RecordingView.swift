import SwiftUI

struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var app: AppState
    let meta: SessionMeta
    let goDate: Date

    @State private var showSummary = false
    @State private var showingFinishOverlay = false

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                HStack {
                    Text("Enregistrement").font(.title2).bold()
                    Spacer()
                    badge
                }

                ProgressView(value: min(app.recorder.elapsed / Double(meta.duration_target_s), 1.0))
                    .tint(.blue)
                    .padding(.vertical)

                HStack {
                    LabeledValue(title: "t (s)", value: String(format: "%.1f", app.recorder.elapsed))
                    LabeledValue(title: "Hz", value: String(format: "%.0f", app.recorder.measuredHz))
                    LabeledValue(title: "|a|", value: String(format: "%.2f", app.recorder.avgAccelNorm))
                    LabeledValue(title: "cadence", value: String(format: "%.0f", app.recorder.estCadenceSpm))
                }

                Spacer(minLength: 0)
                Text("L’enregistrement se termine automatiquement à \(meta.duration_target_s) s.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }

            if showingFinishOverlay {
                Color.black.opacity(0.35).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Fin du test… préparation du résumé")
                        .font(.callout).foregroundStyle(.white)
                }
            }
        }
        // RecordingView.swift — remplace les deux .onChange par ceci
        .onReceive(app.recorder.$state.removeDuplicates()) { s in
            guard s == .finished, !showSummary else { return }
            showingFinishOverlay = true
            // petit délai pour éviter "modifying state during view update"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                showSummary = true
            }
        }

        // garde-fou temps (si jamais .finished n’arrive pas)
        .onReceive(app.recorder.$elapsed) { v in
            if v >= Double(meta.duration_target_s), app.recorder.state != .finished, !showSummary {
                showingFinishOverlay = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { showSummary = true }
            }
        }
        .fullScreenCover(isPresented: $showSummary, onDismiss: {
            showingFinishOverlay = false
            dismiss()
        }) {
            SummaryView(meta: meta) {
                showingFinishOverlay = false
                showSummary = false
                dismiss()
            }
            .environmentObject(app)
        }
    }

    @ViewBuilder private var badge: some View {
        switch app.recorder.state {
        case .recording: Label("REC", systemImage: "dot.circle.fill").foregroundStyle(.red)
        case .paused:    Label("PAUSE", systemImage: "pause.circle").foregroundStyle(.orange)
        case .finished:  Label("FINI", systemImage: "checkmark.circle").foregroundStyle(.green)
        default:         EmptyView()
        }
    }
}
