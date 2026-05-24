//
//  SettingsView+Uninstaller.swift
//  LegitApp
//
//  Created by Milán Várady on 2024.12.26.
//

import SwiftUI

extension SettingsView {
    struct UninstallView: View {
        @Environment(\.openWindow) var openWindow

        var body: some View {
            VStack(alignment: .center) {
                Button(role: .destructive) {
                    openWindow(id: "uninstall-self")
                } label: {
                    Label("Uninstall", systemImage: "trash.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)

                Text("Uninstall LegitApp, related files and cache.", comment: "Settings Uninstall LegitApp view description")
            }
            .padding()
        }
    }
}
