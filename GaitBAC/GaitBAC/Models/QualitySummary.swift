//
//  QualitySummary.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation

struct QualitySummary: Codable {
    var measuredHz: Double
    var droppedPct: Double
    var durationReal: Double
    var cadenceSpm: Double?
    var accelMedianNorm: Double?
    var score: String // OK / Attention / Mauvaise qualité
}
