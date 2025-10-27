//
//  DateFormatter+ISO.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//
import Foundation

extension DateFormatter {
    static func iso8601Full() -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return f
    }
    static func iso8601BasicZ() -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd_HHmmss'Z'"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }
    static func compactTS() -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }
}
