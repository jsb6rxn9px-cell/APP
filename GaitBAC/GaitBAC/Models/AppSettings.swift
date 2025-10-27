//
//  AppSettings.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation

final class AppSettings: ObservableObject, Codable {
    enum CodingKeys: String, CodingKey {
        case durationSec, targetHz, beeps, haptics, strictAnonymization, folderPrefix, useSemicolonDelimiter
    }

    @Published var durationSec: Int = 30
    @Published var targetHz: Int = 100
    @Published var beeps: Bool = true
    @Published var haptics: Bool = true
    @Published var strictAnonymization: Bool = false
    @Published var folderPrefix: String = "GaitBAC"

    // NOUVEAU : permet de produire un CSV au format “européen”
    @Published var useSemicolonDelimiter: Bool = false

    init() {}

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        durationSec = try c.decodeIfPresent(Int.self, forKey: .durationSec) ?? 30
        targetHz = try c.decodeIfPresent(Int.self, forKey: .targetHz) ?? 100
        beeps = try c.decodeIfPresent(Bool.self, forKey: .beeps) ?? true
        haptics = try c.decodeIfPresent(Bool.self, forKey: .haptics) ?? true
        strictAnonymization = try c.decodeIfPresent(Bool.self, forKey: .strictAnonymization) ?? false
        folderPrefix = try c.decodeIfPresent(String.self, forKey: .folderPrefix) ?? "GaitBAC"
        useSemicolonDelimiter = try c.decodeIfPresent(Bool.self, forKey: .useSemicolonDelimiter) ?? false
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
    }
}
