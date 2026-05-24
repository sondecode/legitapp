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

    private let curatedFormulas = [
        "mysql", "postgresql@16", "redis", "nginx", "php",
        "mongodb-community", "elasticsearch", "rabbitmq", "memcached", "sqlite"
    ]

    private var filteredFormulas: [String] {
        if searchText.isEmpty { return curatedFormulas }
        return curatedFormulas.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Install Service")
                .font(.system(size: 18, weight: .bold))

            TextField("Search or enter formula name", text: $searchText)
                .textFieldStyle(.roundedBorder)

            List(filteredFormulas, id: \.self) { formula in
                HStack {
                    Text(formula)
                    Spacer()
                    AsyncButton("Install & Start") {
                        dismiss()
                        await manager.installAndStart(formula: formula)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .frame(minHeight: 200)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}
