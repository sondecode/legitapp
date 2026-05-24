//
//  Cask.swift
//  LegitApp
//
//  Created by Milán Várady on 2022. 10. 04..
//

import SwiftUI
import OSLog

/// A view model that holds all essential data of a Homebrew cask
@MainActor
final class Cask: ObservableObject {
    /// Static cask information
    let info: CaskInfo

    /// Number of downloads in the last 365 days
    let downloadsIn365days: Int

    /// Description shown in the UI. Can be localized or custom.
    let displayedDescription: String

    // MARK: Published properties
    @Published var isInstalled: Bool = false

    /// Progress state of the cask when installing, updating or uninstalling
    @Published var progressState: CaskProgressState = .idle

    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Cask.self)
    )

    required init(info: CaskInfo, downloadsIn365days: Int, isInstalled: Bool = false) {
        self.info = info
        self.downloadsIn365days = downloadsIn365days
        self.isInstalled = isInstalled
        self.displayedDescription = info.description
    }

    static let dummy = Cask(info: CaskInfo(
        token: "test",
        fullToken: "test",
        tap: "homebrew/cask",
        name: "Test",
        description: "Test application",
        homepageURL: URL(string: "https://aerolite.dev/"),
        installMethod: .homebrew,
        pkgInstaller: false,
        warning: nil
    ), downloadsIn365days: 100)
}
