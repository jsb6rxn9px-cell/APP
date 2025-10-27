//
//  ConsentView.swift
//  GaitBAC
//
//  Created by Hugo Roy-Poulin on 2025-09-15.
//

import SwiftUI

struct ConsentView: View {
    @EnvironmentObject var app: AppState
    @State private var refused = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Étude sur la marche & estimation du BAC").font(.title).bold()
                Text(consentText).font(.body).multilineTextAlignment(.leading)
                HStack {
                    Button(role: .destructive) {
                        refused = true
                        AnalyticsLogger.shared.log("consent_refused", settings: app.settings)
                    } label: {
                        Text("Refuser").frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered)

                    Button {
                        app.consentGranted = true
                        AnalyticsLogger.shared.log("consent_granted", settings: app.settings)
                    } label: {
                        Text("J’accepte").frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            if refused {
                Text("Consentement refusé. Fermez l’app pour quitter. Aucune donnée ne sera collectée.")
                    .padding().frame(maxWidth: .infinity).background(.ultraThinMaterial)
            }
        }
        .navigationTitle("Consentement & Info")
    }
}

fileprivate let consentText: String = """
But de l’app. Cette application collecte, pendant une courte marche, des signaux des capteurs du téléphone (accéléromètre/gyroscope) afin d’étudier comment l’alcool peut altérer la marche. L’objectif est de permettre, à terme, d’estimer le dépassement du seuil légal et d’approximer le BAC. IMPORTANT : cette app n’est pas un dispositif médical et ne doit jamais servir à décider si vous pouvez conduire.
En bref (20–60 s) : vous marchez avec le téléphone dans une position standard (ex. poche). L’app enregistre uniquement des données de mouvement et quelques métadonnées techniques. Vous pouvez arrêter à tout moment; les données restent locales tant que vous ne les exportez pas.
Ce que l’app collecte : Participant ID & Session ID, signaux bruts (accélération, rotation, gravité, attitude), contexte technique (modèle d’iPhone, iOS, position, orientation, durée, fréquence mesurée, indicateurs de qualité), BAC saisi manuellement (optionnel) et méthode. Aucune collecte de nom civil, géolocalisation, audio, photos, contacts.
Déroulement : remplir les champs → compte à rebours 10 s → marche 20–60 s → résumé qualité → Enregistrer/Exporter.
Bénéfices & risques : bénéfice direct aucun; risques minimes. Faites l’essai dans un endroit sûr, plat, sans obstacles.
Confidentialité : données anonymisées par Participant ID et stockées localement; rien n’est envoyé sans votre action explicite. Vous pouvez supprimer une session à tout moment dans l’historique.
Volontariat : participation volontaire; vous pouvez refuser ou retirer le consentement à tout moment.
Limites : résultats expérimentaux et possiblement inexacts; ne pas utiliser pour juger l’aptitude à conduire.
Contacts : [Nom / établissement / courriel]. Éthique : [No. d’approbation le cas échéant].
"""
