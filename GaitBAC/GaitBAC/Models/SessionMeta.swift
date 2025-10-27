//
//  SessionMeta.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation

struct SessionMeta: Codable, Identifiable {
    var id: String { session_id }

    // Saisie utilisateur
    var participant_id: String
    var sex: String?
    var age_years: String?       // <- NOUVEAU
    var height_in: String?
    var weight_kg: String?

    var position: PhonePosition
    var condition: Condition

    var bac: Double?
    var bac_method: BACMethod?
    var bac_brand_model: String?
    var bac_measured_at: Date?

    var notes: String?

    // Auto
    let file_schema_version: String = FILE_SCHEMA_VERSION
    let app_version: String = APP_VERSION_STRING
    let device_model: String
    let ios_version: String

    let session_id: String
    let sampling_hz_target: Int
    var sampling_hz_measured: Double = 0
    let duration_target_s: Int
    var duration_recorded_s: Double = 0
    var preroll_s: Double = 0

    var orientation_start: String
    var bac_delay_min: Double?

    var quality_flags: [String: String] = [:]
}
