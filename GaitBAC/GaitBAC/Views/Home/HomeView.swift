//
//  HomeView.swift
//  GaitBAC
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: AppState

    @State private var participantID: String = ""
    @State private var position: PhonePosition = .pocketRight
    @State private var condition: Condition = .unknown

    // BAC
    @State private var bacStr: String = ""
    @State private var bacMethod: BACMethod = .breathalyzer
    @State private var bacMeasuredAt: Date = Date()

    // Demographics
    @State private var sexIdx: Int = 0 // 0=Male, 1=Female
    @State private var age: Int = 25
    @State private var heightIn: Int = 68
    @State private var weightLb: Int = 160

    @State private var showCountdown = false
    @State private var formInvalidReason: String?

    private let ages = Array(18...50)
    private let heights = Array(56...80)      // inches
    private let weights = stride(from: 80, through: 250, by: 10).map { $0 }

    var body: some View {
        Form {
            Section("Participant") {
                TextField("Participant ID", text: $participantID)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Picker("Sex", selection: $sexIdx) {
                    Text("Male").tag(0)
                    Text("Female").tag(1)
                }
                .pickerStyle(.segmented)
                Picker("Age", selection: $age) {
                    ForEach(ages, id: \.self) { Text("\($0)") }
                }
                Picker("Height", selection: $heightIn) {
                    ForEach(heights, id: \.self) { h in
                        Text(inchesToFeetIn(h))
                    }
                }
                Picker("Weight (lb)", selection: $weightLb) {
                    ForEach(weights, id: \.self) { Text("\($0)") }
                }
            }

            Section("Test setup") {
                Picker("Phone position", selection: $position) {
                    ForEach(PhonePosition.allCases) { Text($0.rawValue) }
                }
                Picker("Condition", selection: $condition) {
                    ForEach(Condition.allCases) { Text($0.rawValue) }
                }
                HStack {
                    Text("BAC (0.00–0.40)"); Spacer()
                    TextField("0.00", text: $bacStr)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                Picker("BAC method", selection: $bacMethod) {
                    Text("Breathalyzer").tag(BACMethod.breathalyzer)
                    Text("Other").tag(BACMethod.other)
                }
                DatePicker("BAC time", selection: $bacMeasuredAt)
            }

            Section("Device (read-only)") {
                LabeledContent("iPhone") { Text(DeviceInfo.model) }
                LabeledContent("iOS") { Text(DeviceInfo.iosVersion) }
                LabeledContent("Target rate") { Text("\(app.settings.targetHz) Hz") }
                LabeledContent("Beeps") { Text("Enabled") }
            }

            if let reason = formInvalidReason {
                Text(reason).foregroundStyle(.red)
            }

            Button {
                if validateForm() {
                    showCountdown = true
                    AnalyticsLogger.shared.log("test_started", settings: app.settings)
                }
            } label: { Text("Start recording").frame(maxWidth: .infinity) }
            .disabled(!validateForm(silent: true))
        }
        .navigationTitle("New session")
        .onAppear {
            if participantID.isEmpty {
                participantID = app.settings.lastParticipantID
            }
        }
        .sheet(isPresented: $showCountdown) {
            CountdownView(meta: makeMeta()).environmentObject(app)
        }
    }

    private func inchesToFeetIn(_ inches: Int) -> String {
        let ft = inches / 12
        let ins = inches % 12
        return "\(ft)′\(ins)″"
    }

    private func validateForm(silent: Bool = false) -> Bool {
        formInvalidReason = nil
        if participantID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if !silent { formInvalidReason = "Participant ID required" }
            return false
        }
        if let bac = Double(bacStr), !(0.0...0.4).contains(bac) {
            if !silent { formInvalidReason = "BAC must be in [0.00, 0.40]" }
            return false
        }
        return true
    }

    private func makeMeta() -> SessionMeta {
        let bac = Double(bacStr.replacingOccurrences(of: ",", with: "."))

        return SessionMeta(
            participant_id: participantID,
            sex: (sexIdx == 0 ? "Male" : "Female"),
            age_years: age,
            height_in: heightIn,
            weight_lb: weightLb,
            position: position,
            condition: condition,
            bac: bac,
            bac_method: bacMethod,
            bac_brand_model: nil,
            bac_measured_at: bac != nil ? bacMeasuredAt : nil,
            device_model: DeviceInfo.model,
            ios_version: DeviceInfo.iosVersion,
            session_id: UUID().uuidString,
            sampling_hz_target: app.settings.targetHz,
            sampling_hz_measured: 0,
            duration_recorded_s: 0,
            preroll_s: 0,
            orientation_start: "portrait",
            bac_delay_min: nil,
            quality_flags: [:]
        )
    }
}
