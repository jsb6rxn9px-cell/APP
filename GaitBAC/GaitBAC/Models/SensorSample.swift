//
//  SensorSample.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation

struct SensorSample: Codable, Hashable {
    var t: Double
    var ax: Double
    var ay: Double
    var az: Double
    var gx: Double
    var gy: Double
    var gz: Double
    var qw: Double
    var qx: Double
    var qy: Double
    var qz: Double
    var gravx: Double
    var gravy: Double
    var gravz: Double
    var actType: String?
}
