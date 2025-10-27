//
//  SettingsView.swift
//  GaitBAC
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @State private var soberCalibCount = 2

    var body: some View {
        Form {
            Section("Files & Privacy") {
                TextField("Folder prefix", text: $app.settings.folderPrefix)
                Toggle("Strict anonymization (mask ID)", isOn: $app.settings.strictAnonymization)
            }
            Section("Acquisition (fixed)") {
                LabeledContent("Sampling rate") { Text("100 Hz (fixed)") }
                LabeledContent("Beeps") { Text("Enabled") }
            }
            Section("About") {
                Text("File schema: v\(FILE_SCHEMA_VERSION)")
                Text("App version: \(APP_VERSION_STRING)")
            }
        }
        .navigationTitle("Settings")
    }
}
