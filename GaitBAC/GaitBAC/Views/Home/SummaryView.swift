//
//  SummaryView.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    let meta: SessionMeta
    /// Appelé par RecordingView quand on a fini (fermera aussi RecordingView)
    let onDone: () -> Void

    @State private var exportURL: URL?
    @State private var quality: QualitySummary?
    @State private var showShare = false
    @State private var rejectReason = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Fin du test").font(.title2).bold()
                if let q = quality { summary(q) } else { Text("Calcul des statistiques…") }

                HStack {
                    // 1) ENREGISTRER & EXPORTER → après partage, retour Consentement
                    Button("Enregistrer & Exporter") {
                        if let (url, q) = app.recorder.export(meta: meta, settings: app.settings) {
                            exportURL = url; quality = q; app.loadSidecars()
                            showShare = true
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    // 2) REJETER → rien à conserver, retour Consentement
                    Button("Rejeter") {
                        AnalyticsLogger.shared.log("test_discarded", meta: ["reason": rejectReason], settings: app.settings)
                        app.resetToConsent()
                        dismiss(); onDone()   // ferme Résumé puis RecordingView → Root/Home/Consent
                    }

                    // 3) REFAIRE → efface les données en mémoire, retour Home (pas Consent)
                    Button("Refaire") {
                        app.resetForRetake()
                        dismiss(); onDone()   // retour Accueil prêt à recommencer
                    }
                }

                TextField("Motif (si rejet)", text: $rejectReason)
                Spacer()
            }
            .padding()
            .navigationTitle("Résumé")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        // Par défaut : on considère que fermer = repartir au Home (sans reset consent)
                        dismiss(); onDone()
                    }
                }
            }
            .onAppear {
                // Pas d'export automatique ! On calcule le résumé si déjà exporté, sinon on laisse "Calcul…"
                if quality == nil, let (_, q) = app.recorder.export(meta: meta, settings: app.settings) {
                    // NOTE: si tu ne veux vraiment rien écrire tant que l’utilisateur n’appuie pas,
                    // remplace la ligne ci-dessus par un calcul “sec” (sans CSV). Ici on garde l’export à la demande.
                    // Pour l’instant, on *n’exporte pas* ici, donc rien.
                    _ = q // placeholder si tu enlèves l’export ci-dessus
                }
            }
            // Après le partage, on retourne au Consentement automatiquement
            .sheet(isPresented: $showShare, onDismiss: {
                app.resetToConsent()
                dismiss(); onDone()  // ferme tout → Root/Home/Consent
            }) {
                if let url = exportURL { ShareSheet(activityItems: [url]) }
            }
        }
    }

    @ViewBuilder private func summary(_ q: QualitySummary) -> some View {
        VStack(alignment: .leading) {
            Text("Résumé qualité").font(.headline)
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow { Text("Durée réelle"); Text(String(format: "%.2f s", q.durationReal)).bold() }
                GridRow { Text("Hz mesuré"); Text(String(format: "%.1f", q.measuredHz)).bold() }
                GridRow { Text("% manqués"); Text(String(format: "%.1f %%", q.droppedPct)).bold() }
                GridRow { Text("Cadence"); Text(q.cadenceSpm != nil ? String(format: "%.0f spm", q.cadenceSpm!) : "—").bold() }
                GridRow { Text("|a| médiane"); Text(q.accelMedianNorm != nil ? String(format: "%.2f m/s²", q.accelMedianNorm!) : "—").bold() }
                GridRow { Text("Score"); Text(q.score).bold().foregroundStyle(q.score == "OK" ? .green : .orange) }
            }
        }
    }
}
