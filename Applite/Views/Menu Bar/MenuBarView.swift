//
//  MenuBarView.swift
//  Applite
//

import SwiftUI
import AppKit

/// Main popover content shown when clicking the menu bar icon
struct MenuBarView: View {
    @EnvironmentObject var caskManager: CaskManager
    @ObservedObject var serviceManager = ServiceManager.shared

    private var runningServices: [BrewService] {
        let running = serviceManager.services.filter { $0.status == .started || $0.status == .error }
        let stopped = serviceManager.services.filter { $0.status == .stopped }
        return running + stopped
    }

    private var outdatedCasks: [Cask] {
        Array(caskManager.outdatedCasks.casks.sorted(by: { $0.info.name < $1.info.name }).prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Header
            HStack {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 1) {
                    Text("LegitApp")
                        .font(.headline)
                    Text(summaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows
                        .first { !($0 is NSPanel) && $0.canBecomeMain }
                        .map { $0.makeKeyAndOrderFront(nil) }
                } label: {
                    Image(systemName: "macwindow")
                }
                .buttonStyle(.borderless)
                .help("Open LegitApp")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: Active Tasks
                    if !caskManager.activeTasks.isEmpty {
                        MenuBarSectionHeader(title: "Active Tasks", icon: "gear.badge")

                        ForEach(caskManager.activeTasks, id: \.cask.info.token) { brewTask in
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 16, height: 16)
                                Text(brewTask.cask.info.name)
                                    .font(.callout)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                        }

                        Divider().padding(.vertical, 4)
                    }

                    // MARK: Services
                    MenuBarSectionHeader(title: "Services", icon: "server.rack")

                    if serviceManager.isLoading {
                        HStack {
                            ProgressView().scaleEffect(0.7)
                            Text("Loading…")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    } else if runningServices.isEmpty {
                        Text("No services found")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(runningServices) { service in
                            MenuBarServiceRow(service: service, serviceManager: serviceManager)
                        }
                    }

                    Divider().padding(.vertical, 4)

                    // MARK: Updates
                    MenuBarSectionHeader(title: "Updates", icon: "arrow.triangle.2.circlepath")

                    if outdatedCasks.isEmpty {
                        Text("All apps up to date")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(outdatedCasks) { cask in
                            MenuBarCaskRow(cask: cask)
                        }

                        let totalOutdated = caskManager.outdatedCasks.casks.count
                        if totalOutdated > 5 {
                            Button {
                                Task { caskManager.updateAll(Array(caskManager.outdatedCasks.casks)) }
                            } label: {
                                Text("Update All (\(totalOutdated) apps)")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(Color.accentColor)
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 400)

            Divider()

            // MARK: Footer
            HStack {
                Button {
                    Task { await serviceManager.loadServices() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .font(.callout)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Thoát LegitApp")
                }
                .buttonStyle(.borderless)
                .font(.callout)
                .foregroundStyle(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 300)
        .task {
            await serviceManager.loadServices()
        }
    }

    private var summaryText: String {
        let serviceCount = serviceManager.services.filter { $0.status == .started }.count
        let updateCount = caskManager.outdatedCasks.casks.count
        var parts: [String] = []
        if serviceCount > 0 {
            let serviceString = serviceCount == 1 
                ? String(localized: "1 service running")
                : String(localized: "\(serviceCount) services running")
            parts.append(serviceString)
        }
        if updateCount > 0 {
            let updateString = updateCount == 1
                ? String(localized: "1 update")
                : String(localized: "\(updateCount) updates")
            parts.append(updateString)
        }
        return parts.isEmpty ? String(localized: "All good") : parts.joined(separator: " · ")
    }
}

/// Small section header used inside the menu bar popover
private struct MenuBarSectionHeader: View {
    let title: LocalizedStringKey
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }
}
