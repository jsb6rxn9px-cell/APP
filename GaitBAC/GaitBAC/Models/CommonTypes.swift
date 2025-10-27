//
//  CommonTypes.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation

let FILE_SCHEMA_VERSION = "1.0"
let APP_VERSION_STRING: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

enum PhonePosition: String, CaseIterable, Identifiable, Codable { case pocketRight, pocketLeft; var id: String { rawValue } }

enum Condition: String, CaseIterable, Identifiable, Codable { case sober, afterDrink, unknown, sober_calib; var id: String { rawValue } }

enum BACMethod: String, CaseIterable, Identifiable, Codable { case breathalyzer, other; var id: String { rawValue } }

struct AppInfo: Codable { let deviceModel: String; let iosVersion: String }
