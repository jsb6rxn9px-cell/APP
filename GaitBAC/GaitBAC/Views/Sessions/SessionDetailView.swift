//
//  SessionDetailView.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import SwiftUI

struct SessionDetailView: View {
    let record: SessionRecord
    var body: some View {
        Form {
            Section("Métadonnées") {
                Text("Participant: \(record.meta.participant_id)")
                Text("Session: \(record.meta.session_id)")
                Text("Position: \(record.meta.position.rawValue)")
                Text("Condition: \(record.meta.condition.rawValue)")
                if let bac = record.meta.bac { Text(String(format: "BAC: %.2f", bac)) }
            }
            Section("Qualité") {
                Text(String(format: "Hz mesuré: %.1f", record.quality.measuredHz))
                Text(String(format: "%% manqués: %.1f", record.quality.droppedPct))
                if let c = record.quality.cadenceSpm { Text(String(format: "Cadence: %.0f spm", c)) }
                if let a = record.quality.accelMedianNorm { Text(String(format: "|a| médiane: %.2f", a)) }
                Text("Score: \(record.quality.score)")
            }
        }
        .navigationTitle("Détails")
    }
}
