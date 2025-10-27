//
//  CSVWriter.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation
import CryptoKit

struct CSVWriter {
    static func writeSessionCSV(meta: SessionMeta, samples: [SensorSample], settings: AppSettings, quality: QualitySummary) throws -> URL {
        let ts = DateFormatter.iso8601BasicZ().string(from: Date())

        let participantForName = settings.strictAnonymization ? anonymize(meta.participant_id) : meta.participant_id
        let bacStr = String(format: "%.2f", meta.bac ?? 0.0).replacingOccurrences(of: ".", with: "p")
        let name = "\(ts)_\(participantForName)-\(meta.session_id)_\(meta.position.rawValue)_\(meta.condition.rawValue)_\(bacStr).csv"
        let dir = AppPaths.sessionsDir(prefix: settings.folderPrefix)
        let url = dir.appendingPathComponent(name)

        var text = ""
        func addKV(_ k: String, _ v: String) { text += "# \(k),\(v)\n" } // métadonnées toujours séparées par des virgules

        // Métadonnées
        addKV("file_schema_version", meta.file_schema_version)
        addKV("app_version", meta.app_version)
        addKV("participant_id", participantForName)
        if let sex = meta.sex, !sex.isEmpty { addKV("sex", sex) }
        if let age = meta.age_years, !age.isEmpty { addKV("age_years", age) }
        if let height = meta.height_in, !height.isEmpty { addKV("height_in", height) }
        if let weight = meta.weight_kg, !weight.isEmpty { addKV("weight_kg", weight) }
        addKV("session_id", meta.session_id)
        addKV("device_model", meta.device_model)
        addKV("ios_version", meta.ios_version)
        addKV("position", meta.position.rawValue)
        addKV("orientation_start", meta.orientation_start)
        addKV("condition", meta.condition.rawValue)
        if let bac = meta.bac { addKV("bac", String(format: "%.3f", bac)) }
        if let m = meta.bac_method { addKV("bac_method", m.rawValue) }
        if let bm = meta.bac_brand_model { addKV("bac_brand_model", bm) }
        if let t = meta.bac_measured_at { addKV("bac_measured_at", DateFormatter.iso8601Full().string(from: t)) }
        if let delay = meta.bac_delay_min { addKV("bac_delay_min", String(format: "%.1f", delay)) }
        addKV("sampling_hz_target", String(meta.sampling_hz_target))
        addKV("sampling_hz_measured", String(format: "%.2f", meta.sampling_hz_measured))
        addKV("duration_target_s", String(meta.duration_target_s))
        addKV("duration_recorded_s", String(format: "%.3f", meta.duration_recorded_s))
        addKV("preroll_s", String(format: "%.3f", meta.preroll_s))
        addKV("quality_flags", (try? String(data: JSONEncoder().encode(meta.quality_flags), encoding: .utf8)) ?? "{}")
        if let qData = try? JSONEncoder().encode(quality), let qStr = String(data: qData, encoding: .utf8) {
            addKV("quality_summary", qStr)
        }

        // Choix du séparateur des données
        let sep = settings.useSemicolonDelimiter ? ";" : ","

        // En-tête colonnes (données)
        let headers = ["t","ax","ay","az","gx","gy","gz","qw","qx","qy","qz","gravx","gravy","gravz","actType"]
        text += headers.joined(separator: sep) + "\n"

        // Lignes (t en 6 décimales)
        for s in samples {
            let row: [String] = [
                fmt(s.t), fmt(s.ax), fmt(s.ay), fmt(s.az),
                fmt(s.gx), fmt(s.gy), fmt(s.gz),
                fmt(s.qw), fmt(s.qx), fmt(s.qy), fmt(s.qz),
                fmt(s.gravx), fmt(s.gravy), fmt(s.gravz),
                s.actType ?? ""
            ]
            text += row.joined(separator: sep) + "\n"
        }

        try text.write(to: url, atomically: true, encoding: .utf8)

        // Sidecar JSON (pour l’aperçu)
        let sidecar = AppPaths.sidecarJSON(for: url)
        let record = SessionRecord(meta: meta, samples: [], quality: quality)
        try JSONEncoder().encode(record).write(to: sidecar)

        return url
    }

    private static func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

    private static func anonymize(_ s: String) -> String {
        let data = Data(s.utf8)
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return String(hash.prefix(8))
    }
}
