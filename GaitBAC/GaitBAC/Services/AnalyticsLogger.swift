//
//  AnalyticsLogger.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation

final class AnalyticsLogger {
    static let shared = AnalyticsLogger(); private init() {}
    func log(_ event: String, meta: [String: String] = [:], settings: AppSettings) {
        let url = AppPaths.analyticsLog(prefix: settings.folderPrefix)
        let ts = DateFormatter.iso8601Full().string(from: Date())
        var line = "\(ts),\(event)"
        if !meta.isEmpty {
            let payload = meta.map { "\($0.key)=\($0.value)" }.joined(separator: "|")
            line += ",\(payload)"
        }
        line += "\n"
        if FileManager.default.fileExists(atPath: url.path) {
            if let h = try? FileHandle(forWritingTo: url) {
                h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); try? h.close()
            }
        } else {
            let header = "timestamp,event,meta\n"
            try? (header + line).write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
