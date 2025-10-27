//
//  HelpView.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Aide rapide").font(.title2).bold()
                Text("• Placez le téléphone dans une poche latérale.\n• Restez immobile pendant le compte à rebours.\n• Marchez sur sol plat, sans obstacles.\n• Évitez les virages serrés durant l’essai.")
            }.padding()
        }
        .navigationTitle("Aide")
    }
}
