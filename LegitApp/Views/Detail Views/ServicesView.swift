//
//  ServicesView.swift
//  LegitApp
//

import SwiftUI
import ButtonKit

struct ServicesView: View {
    @StateObject private var manager = ServiceManager.shared
    @State private var showInstallSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if manager.isLoading && manager.services.isEmpty {
                Spacer()
                ProgressView("Loading services…")
                    .frame(maxWidth: .infinity)
                Spacer()
            } else if manager.services.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Services Found",
                    systemImage: "server.rack",
                    description: Text("Install a service using Homebrew to manage it here.")
                )
                Spacer()
            } else {
                List(manager.services) { service in
                    ServiceRowView(service: service, manager: manager)
                }
                .listStyle(.plain)
            }
        }
        .task {
            if manager.services.isEmpty {
                await manager.loadServices()
            }
        }
        .sheet(isPresented: $showInstallSheet) {
            InstallFormulaSheet(manager: manager)
        }
        .navigationTitle("Services")
        .toolbar {
            ToolbarItemGroup {
                AsyncButton {
                    await manager.loadServices()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

                Button {
                    showInstallSheet = true
                } label: {
                    Label("Install Service", systemImage: "plus.circle.fill")
                }
            }
        }
    }
}

#Preview {
    ServicesView()
}
