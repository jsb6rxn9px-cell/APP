//
//  HomeView.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: AppState

    // Requis
    @State private var participantID = "P001"
    @State private var position: PhonePosition = .pocketRight
    @State private var condition: Condition = .unknown

    // Optionnels (NOUVEAU + exposés)
    @State private var sex = ""         // libre: "M/F/Autre" ou texte
    @State private var ageYears = ""    // clavier numberPad
    @State private var heightIn = ""    // pouces
    @State private var weightKg = ""    // kg

    // BAC
    @State private var bacStr = "0.00"
    @State private var bacMethod: BACMethod = .breathalyzer
    @State private var bacBrandModel = ""
    @State private var bacMeasuredAt: Date = Date()
    @State private var notes: String = ""

    // UI
    @State private var showCountdown = false
    @State private var formInvalidReason: String? = nil

    var body: some View {
        Form {
            Section("Champs requis") {
                TextField("Participant ID (ex. P001)", text: $participantID)
                Picker("Position du téléphone", selection: $position) {
                    ForEach(PhonePosition.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Condition", selection: $condition) {
                    ForEach(Condition.allCases) { Text($0.rawValue).tag($0) }
                }
                HStack {
                    Text("BAC (0.00–0.40)"); Spacer()
                    TextField("0.00", text: $bacStr)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                Picker("Méthode BAC", selection: $bacMethod) {
                    Text("Éthylotest").tag(BACMethod.breathalyzer)
                    Text("Autre").tag(BACMethod.other)
                }
                TextField("Marque/Modèle (optionnel)", text: $bacBrandModel)
                DatePicker("Heure mesure BAC", selection: $bacMeasuredAt)
                TextField("Notes (optionnel)", text: $notes, axis: .vertical)
            }

            Section("Champs optionnels") { // <- NOUVEAU
                TextField("Sexe (ex. M/F/Autre)", text: $sex)
                TextField("Âge (années)", text: $ageYears).keyboardType(.numberPad)
                TextField("Taille (pouces)", text: $heightIn).keyboardType(.decimalPad)
                TextField("Poids (kg)", text: $weightKg).keyboardType(.decimalPad)
            }

            Section("Infos auto (lecture seule)") {
                LabeledContent("iPhone") { Text(DeviceInfo.model) }
                LabeledContent("iOS") { Text(DeviceInfo.iosVersion) }
                LabeledContent("Fréquence cible") { Text("\(app.settings.targetHz) Hz") }
            }

            Section("Paramètres rapides") {
                Stepper("Durée: \(app.settings.durationSec) s",
                        value: $app.settings.durationSec, in: 20...60, step: 10)
                Picker("Fréquence", selection: $app.settings.targetHz) {
                    Text("60 Hz").tag(60); Text("100 Hz").tag(100); Text("200 Hz").tag(200)
                }
                Toggle("Bip", isOn: $app.settings.beeps)
                Toggle("Vibration", isOn: $app.settings.haptics)
            }

            if let reason = formInvalidReason { Text(reason).foregroundColor(.red) }

            Button {
                if validateForm() {
                    showCountdown = true
                    AnalyticsLogger.shared.log("test_started", settings: app.settings)
                }
            } label: { Text("Commencer le test").frame(maxWidth: .infinity) }
            .disabled(!validateForm(silent: true))
        }
        .navigationTitle("Démarrer un test")
        .sheet(isPresented: $showCountdown) {
            CountdownView(meta: makeMeta()).environmentObject(app)
        }
    }

    private func validateForm(silent: Bool = false) -> Bool {
        guard Validators.isValidParticipantID(participantID) else {
            if !silent { formInvalidReason = "Participant ID invalide" }; return false
        }
        let (ok, _) = Validators.isValidBAC(bacStr)
        guard ok else { if !silent { formInvalidReason = "BAC invalide (0.00–0.40)" }; return false }
        guard bacMeasuredAt <= Date() else { if !silent { formInvalidReason = "Heure BAC dans le futur" }; return false }
        formInvalidReason = nil; return true
    }

    private func makeMeta() -> SessionMeta {
        let appInfo = AppInfo(deviceModel: DeviceInfo.model, iosVersion: DeviceInfo.iosVersion)
        let sid = {
            let ts = DateFormatter.compactTS().string(from: Date())
            let uuid = UUID().uuidString.split(separator: "-").first ?? "XXXX"
            return "\(ts)_\(uuid)"
        }()

        let (ok, value) = Validators.isValidBAC(bacStr)
        let start = Date()
        var m = SessionMeta(
            participant_id: participantID,
            sex: sex.isEmpty ? nil : sex,
            age_years: ageYears.isEmpty ? nil : ageYears,
            height_in: heightIn.isEmpty ? nil : heightIn,
            weight_kg: weightKg.isEmpty ? nil : weightKg,
            position: position,
            condition: condition,
            bac: ok ? value : nil,
            bac_method: bacMethod,
            bac_brand_model: bacBrandModel.isEmpty ? nil : bacBrandModel,
            bac_measured_at: bacMeasuredAt,
            notes: notes.isEmpty ? nil : notes,
            device_model: appInfo.deviceModel,
            ios_version: appInfo.iosVersion,
            session_id: sid,
            sampling_hz_target: app.settings.targetHz,
            duration_target_s: app.settings.durationSec,
            orientation_start: UIDevice.current.orientation.isLandscape ? "landscape" : "portrait",
            bac_delay_min: Validators.bacDelayMinutes(start: start, bacTime: bacMeasuredAt)
        )
        m.preroll_s = 2.0
        return m
    }
}
