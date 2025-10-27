//
//  AppPaths.swift
//  GaitBAC
//

import Foundation

enum AppPaths {
    static func baseDir(prefix: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(prefix, isDirectory: true)
    }
    static func sessionsDir(prefix: String) -> URL {
        let d = baseDir(prefix: prefix).appendingPathComponent("sessions", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    static func analyticsLog(prefix: String) -> URL {
        let d = baseDir(prefix: prefix)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d.appendingPathComponent("analytics_log.csv")
    }
    static func sidecarJSON(for csvURL: URL) -> URL {
        csvURL.deletingPathExtension().appendingPathExtension("json")
    }
}
