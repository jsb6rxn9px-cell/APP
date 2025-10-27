//
//  RootView.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//
import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        TabView {
            NavigationStack {
                if app.consentGranted {
                    HomeView()
                } else {
                    ConsentView()
                }
            }
            .tabItem { Label("Accueil", systemImage: "house") }

            NavigationStack { SessionsListView() }
                .tabItem { Label("Sessions", systemImage: "list.bullet") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Réglages", systemImage: "gear") }

            NavigationStack { HelpView() }
                .tabItem { Label("Aide", systemImage: "questionmark.circle") }
        }
        .onAppear { AnalyticsLogger.shared.log("app_open", settings: app.settings) }
    }
}

