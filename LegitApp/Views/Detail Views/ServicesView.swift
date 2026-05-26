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
            if manager.isLoading && manager.services.isEmpty && manager.installedFormulae.isEmpty {
                Spacer()
                ProgressView("Loading services…")
                    .frame(maxWidth: .infinity)
                Spacer()
            } else if manager.services.isEmpty && manager.installedFormulae.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Services Found",
                    systemImage: "server.rack",
                    description: Text("Install a service using Homebrew to manage it here.")
                )
                Spacer()
            } else {
                List {
                    if !manager.services.isEmpty {
                        Section("Services") {
                            ForEach(manager.services) { service in
                                ServiceRowView(service: service, manager: manager)
                            }
                        }
                    }

                    if !manager.installedFormulae.isEmpty {
                        Section("Installed Formulae") {
                            ForEach(manager.installedFormulae) { formula in
                                FormulaRowView(formula: formula, manager: manager)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            if manager.services.isEmpty && manager.installedFormulae.isEmpty {
                await manager.loadAll()
            }
        }
        .sheet(isPresented: $showInstallSheet) {
            InstallFormulaSheet(manager: manager)
        }
        .alertManager(manager.alert)
        .navigationTitle("Services")
        .toolbar {
            ToolbarItemGroup {
                AsyncButton {
                    await manager.loadAll()
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
