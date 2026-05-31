//
//  CaskManager.swift
//  LegitApp
//
//  Created by Milán Várady on 2022. 10. 04..
//

import Foundation
import OSLog
import SwiftUI

typealias CaskId = String
typealias TapId = String
typealias BrewAnalyticsDictionary = [CaskId: Int]
typealias BrewTask = (cask: Cask, task: Task<Void, Never>)

/// Holds all cask data and provides methods to take actions on them (e.g. install, update)
@MainActor
final class CaskManager: ObservableObject {
    /// Cask view models
    @Published var casks: [CaskId: Cask] = [:]
    /// All currently running brew tasks
    @Published var activeTasks: [BrewTask] = []
    @Published var alert = AlertManager()

    /// The data coordinator that orchestrates data loading
    lazy var dataCoordinator = CaskDataCoordinator()

    // Searchble cask collections
    let allCasks = SearchableCaskCollection()
    let installedCasks = SearchableCaskCollection()
    let outdatedCasks = SearchableCaskCollection()
    @Published var taps: [TapViewModel] = []

    // Precompiled cask category dicts
    @Published var categories: [CategoryViewModel] = []
    @Published var bannerConfig: BannerConfig?

    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CaskManager.self)
    )

    init() {}
}
