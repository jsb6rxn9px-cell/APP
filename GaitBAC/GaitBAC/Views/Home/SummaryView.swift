//
//  SummaryView.swift
//  GaitBAC
//

import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    let meta: SessionMeta
    let onDone: () -> Void

    @State private var exportURL: URL?
    @State private var quality: QualitySummary?
    @State private var showShare = false
    @State private var rejectReason = "user_choice"

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if app.recorder.elapsed < 20 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Durée insuffisante (<20 s)")
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.yellow.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let q = quality {
                    Text("Qualité: \(q.score) — \(String(format: \"%.2f\", q.measuredHz)) Hz, drop \(String(format: \"%.1f\", q.droppedPct))%")
                } else {
                    Text("Prêt à enregistrer le fichier et partager…")
                }

                Spacer()

                HStack {
                    Button("Enregistrer & Exporter") {
                        var m = meta
                        if app.recorder.elapsed < 20 {
                            m.quality_flags["short"] = "true"
                        }
                        if let (url, q) = app.recorder.export(meta: m, settings: app.settings) {
                            exportURL = url; quality = q; app.loadSidecars()
                            // Auto-increment participant ID after successful save
                            app.settings.lastParticipantID = app.settings.nextParticipantID()
                            showShare = true
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Rejeter") {
                        AnalyticsLogger.shared.log("test_discarded", meta: ["reason": rejectReason], settings: app.settings)
                        app.resetToConsent()
                        dismiss(); onDone()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .padding()
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss(); onDone() }
                }
            }
            .sheet(isPresented: $showShare, onDismiss: { dismiss(); onDone() }) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                } else {
                    Text("Nothing to share")
                }
            }
        }
    }
}

// Minimal share sheet helper
import UIKit
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
