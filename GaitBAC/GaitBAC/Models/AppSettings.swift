//
//  AppSettings.swift
//  GaitBAC
//

import Foundation

final class AppSettings: ObservableObject, Codable {
    enum CodingKeys: String, CodingKey {
        case durationSec, targetHz, beeps, haptics, strictAnonymization, folderPrefix, useSemicolonDelimiter
        case lastParticipantID
    }

    // Legacy (ignored in logic but kept for back-compat)
    @Published var durationSec: Int = 30
    @Published var haptics: Bool = false

    // Active settings
    @Published var targetHz: Int = 100
    @Published var beeps: Bool = true
    @Published var strictAnonymization: Bool = false
    @Published var folderPrefix: String = "GaitBAC"
    @Published var useSemicolonDelimiter: Bool = false

    // New: participant auto-increment
    @Published var lastParticipantID: String = "P001"

    // MARK: - Codable
    init() {}

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        durationSec = try c.decodeIfPresent(Int.self, forKey: .durationSec) ?? 30
        targetHz = try c.decodeIfPresent(Int.self, forKey: .targetHz) ?? 100
        beeps = try c.decodeIfPresent(Bool.self, forKey: .beeps) ?? true
        haptics = try c.decodeIfPresent(Bool.self, forKey: .haptics) ?? false
        strictAnonymization = try c.decodeIfPresent(Bool.self, forKey: .strictAnonymization) ?? false
        folderPrefix = try c.decodeIfPresent(String.self, forKey: .folderPrefix) ?? "GaitBAC"
        useSemicolonDelimiter = try c.decodeIfPresent(Bool.self, forKey: .useSemicolonDelimiter) ?? false
        lastParticipantID = try c.decodeIfPresent(String.self, forKey: .lastParticipantID) ?? "P001"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(durationSec, forKey: .durationSec)
        try c.encode(targetHz, forKey: .targetHz)
        try c.encode(beeps, forKey: .beeps)
        try c.encode(haptics, forKey: .haptics)
        try c.encode(strictAnonymization, forKey: .strictAnonymization)
        try c.encode(folderPrefix, forKey: .folderPrefix)
        try c.encode(useSemicolonDelimiter, forKey: .useSemicolonDelimiter)
        try c.encode(lastParticipantID, forKey: .lastParticipantID)
    }

    /// "P001" -> "P002" ; "P9" -> "P10" ; "X099" -> "X100"
    func nextParticipantID() -> String {
        let s = lastParticipantID
        let digits = s.reversed().prefix { $0.isNumber }.reversed()
        let prefix = s.dropLast(digits.count)
        if let n = Int(String(digits)) {
            let width = digits.count
            let next = n + 1
            let formatted = String(format: "%0\(width)d", next)
            return prefix + formatted
        } else {
            return s + "2" // fallback if no trailing number
        }
    }
}
