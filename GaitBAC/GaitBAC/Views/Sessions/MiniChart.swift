//
//  MiniChart.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import SwiftUI
import Charts

struct MiniChart: View {
    @EnvironmentObject var app: AppState
    let record: SessionRecord

    var body: some View {
        if let url = try? findCSV(for: record.meta.session_id),
           let (times, mags) = try? loadMagnitudePreview(from: url, maxPoints: 500) {

            // IMPORTANT : Array(...) pour satisfaire RandomAccessCollection
            let pairs: [(Double, Double)] = Array(zip(times, mags))

            if #available(iOS 16.0, *) {
                Chart(pairs, id: \.0) { pair in
                    LineMark(
                        x: .value("t", pair.0),
                        y: .value("|a|", pair.1)
                    )
                }
            } else {
                Text("Aperçu non disponible sur cette version d’iOS")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private func findCSV(for sid: String) throws -> URL {
        let dir = AppPaths.sessionsDir(prefix: app.settings.folderPrefix)
        let urls = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        guard let u = urls.first(where: { $0.lastPathComponent.contains(sid) && $0.pathExtension == "csv" }) else {
            throw NSError(domain: "MiniChart", code: 404)
        }
        return u
    }
}

// Lecture rapide des premiers points (t, |a|) pour l’aperçu
func loadMagnitudePreview(from url: URL, maxPoints: Int) throws -> ([Double], [Double]) {
    // Variante non-dépréciée avec encodage
    let data = try String(contentsOf: url, encoding: .utf8)
    let lines = data.split(separator: "\n")

    var times: [Double] = []
    var mags: [Double] = []

    for line in lines {
        if line.first == "#" { continue }               // ignore les métadonnées
        if line.starts(with: "t,ax,ay,az") { continue } // ignore l’en-tête colonnes
        let parts = line.split(separator: ",")
        if parts.count < 4 { continue }

        if let t = Double(parts[0]),
           let ax = Double(parts[1]),
           let ay = Double(parts[2]),
           let az = Double(parts[3]) {
            let m = sqrt(ax*ax + ay*ay + az*az)
            times.append(t); mags.append(m)
        }
        if times.count >= maxPoints { break }
    }
    return (times, mags)
}

