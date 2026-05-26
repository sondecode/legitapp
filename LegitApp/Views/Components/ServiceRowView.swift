//
//  ServiceRowView.swift
//  LegitApp
//

import SwiftUI
import ButtonKit

struct ServiceRowView: View {
    let service: BrewService
    @ObservedObject var manager: ServiceManager

    @State private var showUninstallConfirmation = false

    private var isActive: Bool { manager.activeTasks.contains(service.name) }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .font(.system(size: 14, weight: .semibold))

                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    Text(service.status.label)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isActive {
                ProgressView()
                    .controlSize(.small)
                    .padding(.trailing, 6)
            } else {
                HStack(spacing: 6) {
                    if service.status == .stopped || service.status == .error {
                        AsyncButton("Start") {
                            await manager.start(service: service)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    if service.status == .started {
                        AsyncButton("Stop") {
                            await manager.stop(service: service)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        AsyncButton("Restart") {
                            await manager.restart(service: service)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Button("Uninstall", role: .destructive) {
                        showUninstallConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 6)
        .confirmationDialog(
            "Uninstall Service?",
            isPresented: $showUninstallConfirmation,
            titleVisibility: .visible
        ) {
            AsyncButton("Uninstall \(service.name)", role: .destructive) {
                await manager.uninstall(service: service)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will stop and uninstall \(service.name) from Homebrew. Related data files may remain on disk.")
        }
    }

    private var statusColor: Color {
        switch service.status {
        case .started: return .green
        case .stopped: return .gray
        case .error:   return .red
        case .unknown: return .yellow
        }
    }
}

struct FormulaRowView: View {
    let formula: BrewFormula
    @ObservedObject var manager: ServiceManager

    @State private var showUninstallConfirmation = false

    private var isActive: Bool { manager.activeTasks.contains(formula.name) }
    private var hasService: Bool { manager.services.contains { $0.name == formula.name } }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formula.name)
                    .font(.system(size: 14, weight: .semibold))

                HStack(spacing: 6) {
                    if let version = formula.version {
                        Text(version)
                    } else {
                        Text("Unknown version")
                    }

                    if !hasService {
                        Text("No service")
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }

            Spacer()

            if isActive {
                ProgressView()
                    .controlSize(.small)
                    .padding(.trailing, 6)
            } else {
                HStack(spacing: 6) {
                    if formula.isVersioned {
                        AsyncButton("Set Default") {
                            await manager.setDefaultVersion(formula: formula)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Button("Uninstall", role: .destructive) {
                        showUninstallConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 6)
        .confirmationDialog(
            "Uninstall Formula?",
            isPresented: $showUninstallConfirmation,
            titleVisibility: .visible
        ) {
            AsyncButton("Uninstall \(formula.name)", role: .destructive) {
                await manager.uninstall(formula: formula)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will uninstall \(formula.name) from Homebrew. Related data files may remain on disk.")
        }
    }
}
