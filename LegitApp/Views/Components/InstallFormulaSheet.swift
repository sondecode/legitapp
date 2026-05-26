//
//  InstallFormulaSheet.swift
//  LegitApp
//

import SwiftUI
import ButtonKit

struct InstallFormulaSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: ServiceManager

    @State private var searchText = ""
    @State private var installingFormula: String?

    private let curatedFormulas = [
        "mysql", "postgresql@18", "postgresql@17", "postgresql@16", "postgresql@15", "redis", "nginx", "php",
        "mongodb-community", "elasticsearch", "rabbitmq", "memcached", "sqlite"
    ]

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredFormulas: [String] {
        if normalizedSearchText.isEmpty { return curatedFormulas }
        return curatedFormulas.filter { $0.localizedCaseInsensitiveContains(normalizedSearchText) }
    }

    private var canInstallCustomFormula: Bool {
        guard !normalizedSearchText.isEmpty else { return false }
        guard !normalizedSearchText.contains(where: \.isWhitespace) else { return false }
        return !curatedFormulas.contains { $0.caseInsensitiveCompare(normalizedSearchText) == .orderedSame }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Install Service")
                .font(.system(size: 18, weight: .bold))

            TextField("Search or enter formula name", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .disabled(installingFormula != nil)

            List(filteredFormulas, id: \.self) { formula in
                FormulaInstallRow(
                    formula: formula,
                    isInstalling: installingFormula == formula,
                    isDisabled: installingFormula != nil,
                    install: install
                )
            }
            .frame(minHeight: 200)

            if canInstallCustomFormula {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Install custom formula")
                            .font(.system(size: 13, weight: .semibold))
                        Text(normalizedSearchText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    AsyncButton {
                        await install(normalizedSearchText)
                    } label: {
                        if installingFormula == normalizedSearchText {
                            ProgressView()
                                .controlSize(.small)
                            Text("Installing")
                        } else {
                            Text("Install & Start")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(installingFormula != nil)
                }
                .padding(10)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack {
                if let installingFormula {
                    ProgressView()
                        .controlSize(.small)
                    Text("Installing \(installingFormula)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .disabled(installingFormula != nil)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    private func install(_ formula: String) async {
        installingFormula = formula
        let didInstall = await manager.installAndStart(formula: formula)
        installingFormula = nil

        if didInstall {
            dismiss()
        }
    }
}

private struct FormulaInstallRow: View {
    let formula: String
    let isInstalling: Bool
    let isDisabled: Bool
    let install: (String) async -> Void

    var body: some View {
        HStack {
            Text(formula)
            Spacer()
            AsyncButton {
                await install(formula)
            } label: {
                if isInstalling {
                    ProgressView()
                        .controlSize(.small)
                    Text("Installing")
                } else {
                    Text("Install & Start")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isDisabled)
        }
    }
}
