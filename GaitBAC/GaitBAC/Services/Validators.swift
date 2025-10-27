//
//  Validators.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation

enum Validators {
    static func isValidParticipantID(_ s: String) -> Bool {
        guard (1...20).contains(s.count) else { return false }
        return s.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil
    }
    static func isValidBAC(_ value: String) -> (Bool, Double?) {
        if let d = Double(value), d >= 0.0, d <= 0.40 { return (true, d) }
        return (false, nil)
    }
    static func bacDelayMinutes(start: Date, bacTime: Date?) -> Double? {
        guard let t = bacTime else { return nil }
        return start.timeIntervalSince(t) / 60.0
    }
}
