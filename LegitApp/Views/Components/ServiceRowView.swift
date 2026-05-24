//
//  ServiceRowView.swift
//  LegitApp
//

import SwiftUI
import ButtonKit

struct ServiceRowView: View {
    let service: BrewService
    @ObservedObject var manager: ServiceManager

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
                }
            }
        }
        .padding(.vertical, 6)
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
