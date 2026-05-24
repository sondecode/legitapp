//
//  MenuBarServiceRow.swift
//  LegitApp
//

import SwiftUI
import ButtonKit

/// A compact service row for the menu bar popover
struct MenuBarServiceRow: View {
    let service: BrewService
    @ObservedObject var serviceManager: ServiceManager

    private var isBusy: Bool {
        serviceManager.activeTasks.contains(service.name)
    }

    private var statusColor: Color {
        switch service.status {
        case .started: return .green
        case .stopped: return .gray
        case .error:   return .red
        case .unknown: return .yellow
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)

            Text(service.name)
                .font(.callout)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isBusy {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 20, height: 20)
            } else {
                switch service.status {
                case .started:
                    AsyncButton {
                        await serviceManager.stop(service: service)
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Stop \(service.name)")

                    AsyncButton {
                        await serviceManager.restart(service: service)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Restart \(service.name)")

                case .stopped, .unknown:
                    AsyncButton {
                        await serviceManager.start(service: service)
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.accentColor)
                    .help("Start \(service.name)")

                case .error:
                    AsyncButton {
                        await serviceManager.restart(service: service)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.orange)
                    .help("Restart \(service.name)")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
