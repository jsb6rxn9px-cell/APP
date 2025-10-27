//
//  DeviceInfo.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import Foundation
import UIKit

enum DeviceInfo {
    static var model: String {
        var systemInfo = utsname(); uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in String(cString: ptr) }
        }
        return machine
    }
    static var iosVersion: String { UIDevice.current.systemVersion }
}
