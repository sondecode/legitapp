//
//  MenuBarCaskRow.swift
//  LegitApp
//

import SwiftUI

/// A compact outdated cask row for the menu bar popover
struct MenuBarCaskRow: View {
    @ObservedObject var cask: Cask
    @EnvironmentObject var caskManager: CaskManager

    private var isBusy: Bool {
        cask.progressState != .idle
    }

    var body: some View {
        HStack(spacing: 8) {
            if let iconURL = URL(string: "https://github.com/App-Fair/appcasks/releases/download/cask-\(cask.info.token)/AppIcon.png"),
               let faviconURL = URL(string: "https://icon.horse/icon/\(cask.info.homepageURL?.host ?? "")") {
                AppIconView(
                    iconURL: iconURL,
                    faviconURL: faviconURL,
                    cacheKey: cask.info.token,
                    size: 22
                )
            }

            Text(cask.info.name)
                .font(.callout)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isBusy {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 28, height: 20)
            } else {
                Button {
                    Task { caskManager.update(cask) }
                } label: {
                    Text("Update")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)
                .font(.callout)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }
}
