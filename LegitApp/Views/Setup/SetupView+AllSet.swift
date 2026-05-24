//
//  SetupView+AllSet.swift
//  LegitApp
//
//  Created by Milán Várady on 2024.12.26.
//

import SwiftUI
import ButtonKit

extension SetupView {
    /// Page shown when setup is complete
    struct AllSet: View {
        @AppStorage(Preferences.setupComplete.rawValue) var setupComplete = false
        @StateObject private var readinessAlert = AlertManager()
        @State private var isPreparing = false

        var body: some View {
            Text("All set!", comment: "Setup done message")
                .font(.legitLargeTitle)
                .padding(.top, 40)

            Text(
                "LegitApp will check required components before opening the main screen. Please wait until this step finishes, otherwise the app cannot work correctly.",
                comment: "Setup dependency readiness message"
            )
            .multilineTextAlignment(.center)
            .frame(width: 460)

            AsyncButton {
                isPreparing = true
                defer { isPreparing = false }

                do {
                    try await DependencyManager.prepareForMainApp()
                    setupComplete = true
                } catch {
                    readinessAlert.show(title: "Dependencies are not ready", message: error.localizedDescription)
                }
            } label: {
                if isPreparing {
                    Label("Preparing LegitApp...", systemImage: "hourglass")
                } else {
                    Label("Start Using LegitApp", systemImage: "checkmark.circle")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(isPreparing)
            .alert(readinessAlert.title, isPresented: $readinessAlert.isPresented) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(readinessAlert.message)
            }
        }
    }
}
