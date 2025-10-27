//
//  LabeledValue.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import SwiftUI

struct LabeledValue: View {
    let title: String
    let value: String
    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3).monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}
