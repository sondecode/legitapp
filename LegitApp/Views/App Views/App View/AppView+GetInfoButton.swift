//
//  AppView+GetInfoButton.swift
//  LegitApp
//
//  Created by Milán Várady on 2025.01.02.
//

import SwiftUI
import ButtonKit
import OSLog

extension AppView {
    struct GetInfoButton: View {
        @ObservedObject var cask: Cask
        @EnvironmentObject var caskManager: CaskManager
        @Environment(\.openWindow) var openWindow

        @StateObject var alert = AlertManager()

        private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "GetInfoButton")

        var body: some View {
            AsyncButton {
                let caskInfo = try await caskManager.getAdditionalInfoForCask(cask)
                openWindow(value: caskInfo)
            } label: {
                Label("Get Info", systemImage: "info.circle")
            }
            .onButtonStateError { event in
                alert.show(error: event.error, title: "Failed to gather cask info")
                logger.error("Failed to gather additional cask info: \(event.error.localizedDescription)")
            }
            .asyncButtonStyle(.trailing)
            .alertManager(alert)
        }
    }
}
