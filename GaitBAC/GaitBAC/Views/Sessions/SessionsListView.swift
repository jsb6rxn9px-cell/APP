//
//  SessionsLiestView.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import SwiftUI

struct SessionsListView: View {
    @EnvironmentObject var app: AppState
    @State private var shareURL: URL?
    @State private var showShare = false

    var body: some View {
        List {
            ForEach(app.sessions) { rec in
                NavigationLink(destination: SessionDetailView(record: rec)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(rec.meta.participant_id) • \(rec.meta.session_id)").bold()
                            Spacer(); Text(rec.meta.position.rawValue).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 12) {
                            Text(rec.meta.condition.rawValue)
                            Text(String(format: "BAC %.2f", rec.meta.bac ?? 0.0))
                            Text(String(format: "Hz %.0f", rec.quality.measuredHz))
                            Text(rec.quality.score)
                        }.font(.caption).foregroundStyle(.secondary)
                        MiniChart(record: rec).frame(height: 60)
                    }
                }
                .swipeActions {
                    Button {
                        let dir = AppPaths.sessionsDir(prefix: app.settings.folderPrefix)
                        if let csv = try? FileManager.default
                            .contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                            .first(where: { $0.lastPathComponent.contains(rec.meta.session_id) && $0.pathExtension == "csv" }) {
                            shareURL = csv; showShare = true
                        }
                    } label: { Label("Partager", systemImage: "square.and.arrow.up") }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sessions")
        .sheet(isPresented: $showShare) { if let u = shareURL { ShareSheet(activityItems: [u]) } }
    }
}
