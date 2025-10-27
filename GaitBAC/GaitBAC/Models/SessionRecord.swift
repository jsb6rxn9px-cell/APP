//
//  SessionRecord.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation

struct SessionRecord: Identifiable, Codable {
    var id: String { meta.session_id }
    var meta: SessionMeta
    var samples: [SensorSample]
    var quality: QualitySummary
}
