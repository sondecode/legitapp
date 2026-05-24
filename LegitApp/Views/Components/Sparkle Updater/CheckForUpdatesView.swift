//
//  CheckForUpdatesView.swift
//  LegitApp
//
//  Created by Milán Várady on 2023. 07. 29..
//
// Copy pasta from: https://sparkle-project.org/documentation/programmatic-setup/

import SwiftUI
import Sparkle
import Combine

/// This view model class publishes when new updates can be checked by the user
@MainActor
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    private var cancellables = Set<AnyCancellable>()

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.canCheckForUpdates = value
            }
            .store(in: &cancellables)
    }
}

/// A button that opens sparkle updater and checks for available updates
@MainActor
struct CheckForUpdatesView<T: View>: View {
    @StateObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    let label: () -> T

    init(updater: SPUUpdater, @ViewBuilder label: @escaping () -> T) {
        self.updater = updater
        self._checkForUpdatesViewModel = StateObject(wrappedValue: CheckForUpdatesViewModel(updater: updater))
        self.label = label
    }

    var body: some View {
        Button {
            updater.checkForUpdates()
        } label: {
            label()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

