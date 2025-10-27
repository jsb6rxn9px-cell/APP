//
//  CSVWriter.swift
//  GaitBAC
//

import Foundation
import CryptoKit

struct CSVWriter {
    static func writeSessionCSV(meta: SessionMeta, samples: [SensorSample], settings: AppSettings, quality: QualitySummary) throws -> URL {
        // Filename per spec
        let ts = DateFormatter.yyyyMMdd_HHmmss().string(from: Date())
        let participantForName = settings.strictAnonymization ? anonymize(meta.participant_id) : meta.participant_id
        let durSec = Int(round(quality.durationReal))
        let name = "imu_\(participantForName)_\(ts)_dur\(durSec).csv"

        let dir = AppPaths.sessionsDir(prefix: settings.folderPrefix)
        let url = dir.appendingPathComponent(name)

        var text = ""
        func addKV(_ k: String, _ v: String) { text += "# \(k),\(v)\n" } // metadata lines always comma

        // Metadata block
        addKV("file_schema_version", meta.file_schema_version)
        addKV("app_version", meta.app_version)
        addKV("participant_id", participantForName)
        if let sex = meta.sex { addKV("sex", sex) }
        if let age = meta.age_years { addKV("age_years", String(age)) }
        if let height = meta.height_in { addKV("height_in", String(height)) }
        if let weight = meta.weight_lb { addKV("weight_lb", String(weight)) }
        addKV("session_id", meta.session_id)
        addKV("device_model", meta.device_model)
        addKV("ios_version", meta.ios_version)
        addKV("position", meta.position.rawValue)
        addKV("orientation_start", meta.orientation_start)
        addKV("condition", meta.condition.rawValue)
        if let bac = meta.bac { addKV("bac", String(format: "%.3f", bac)) }
        if let m = meta.bac_method { addKV("bac_method", m.rawValue) }
        if let t = meta.bac_measured_at { addKV("bac_measured_at", DateFormatter.iso8601Full().string(from: t)) }
        if let delay = meta.bac_delay_min { addKV("bac_delay_min", String(format: "%.1f", delay)) }
        addKV("sampling_hz_target", String(meta.sampling_hz_target))
        addKV("sampling_hz_measured", String(format: "%.2f", quality.measuredHz))
        addKV("duration_target_s", String(meta.duration_target_s))
        addKV("duration_recorded_s", String(format: "%.3f", quality.durationReal))
        addKV("preroll_s", String(format: "%.3f", meta.preroll_s))
        if !meta.quality_flags.isEmpty, let qf = try? String(data: JSONEncoder().encode(meta.quality_flags), encoding: .utf8) {
            addKV("quality_flags", qf)
        }
        if let qData = try? JSONEncoder().encode(quality), let qStr = String(data: qData, encoding: .utf8) {
            addKV("quality_summary", qStr)
        }

        // Data header
        text += "# data\n"
        let sep = settings.useSemicolonDelimiter ? ";" : ","
        text += [
            "t", "ax","ay","az","gx","gy","gz",
            "qw","qx","qy","qz","gravx","gravy","gravz","actType"
        ].joined(separator: sep) + "\n"

        // Samples
        for s in samples {
            let row: [String] = [
                fmt(s.t),
                fmt(s.ax), fmt(s.ay), fmt(s.az),
                fmt(s.gx), fmt(s.gy), fmt(s.gz),
                fmt(s.qw), fmt(s.qx), fmt(s.qy), fmt(s.qz),
                fmt(s.gravx), fmt(s.gravy), fmt(s.gravz),
                s.actType ?? ""
            ]
            text += row.joined(separator: sep) + "\n"
        }

        try text.write(to: url, atomically: true, encoding: .utf8)

        // Sidecar JSON for previews
        let sidecar = AppPaths.sidecarJSON(for: url)
        let record = SessionRecord(meta: meta, samples: [], quality: quality)
        try JSONEncoder().encode(record).write(to: sidecar)

        return url
    }

    private static func fmt(_ d: Double) -> String { String(format: "%.9f", d) }

    private static func anonymize(_ s: String) -> String {
        let data = Data(s.utf8)
        let digest = SHA256.hash(data: data)
        let hex = digest.compactMap { String(format: "%02x", $0) }.joined()
        return String(hex.prefix(8))
    }
}

// Date helpers
extension DateFormatter {
    static func yyyyMMdd_HHmmss() -> DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }
    static func iso8601Full() -> DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }
}
