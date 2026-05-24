//
//  LegitAppApp.swift
//  LegitApp
//
//  Created by Milán Várady on 2022. 09. 24..
//

import Foundation
import SwiftUI
import Sparkle
import Kingfisher

@main
struct LegitApp: App {
    @NSApplicationDelegateAdaptor(ApplicationDelegate.self) var appDelegate

    @StateObject var caskManager = CaskManager()
    
    @AppStorage(Preferences.colorSchemePreference.rawValue) var colorSchemePreference: ColorSchemePreference = .system
    @AppStorage(Preferences.setupComplete.rawValue) var setupComplete: Bool = false
    @AppStorage(Preferences.showMenuBarIcon.rawValue) var showMenuBarIcon: Bool = true
    
    /// Sparkle update controller
    private let updaterController = SPUStandardUpdaterController.shared
    
    var selectedColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    init() {
        AppLanguage.ensureDefaultLanguageForFirstLaunch()

        // Record the first launch date (once, on very first run)
        if UserDefaults.standard.object(forKey: Preferences.firstLaunchDate.rawValue) == nil {
            UserDefaults.standard.set(Date(), forKey: Preferences.firstLaunchDate.rawValue)
        }

        // Setup network proxy for Kingfisher
        KingfisherManager.shared.downloader.sessionConfiguration = NetworkProxyManager.getURLSessionConfiguration()

        Task {
            await AnalyticsManager.shared.trackAppOpenIfNeeded()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if setupComplete {
                ContentView()
                    .environmentObject(caskManager)
                    .frame(minWidth: 970, minHeight: 520)
                    .preferredColorScheme(selectedColorScheme)
            } else {
                SetupView()
                    .frame(width: 600, height: 400)
                    .preferredColorScheme(selectedColorScheme)
            }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandsMenu(updaterController: updaterController)
        }
        
        Settings {
            SettingsView(updater: updaterController.updater)
                .preferredColorScheme(selectedColorScheme)
        }
        .windowResizability(.contentSize)
        
        Window("Uninstall LegitApp", id: "uninstall-self") {
            UninstallSelfView()
                .padding()
                .preferredColorScheme(selectedColorScheme)
        }
        .windowResizability(.contentSize)

        WindowGroup("Shell Output", for: String.self) { $errorString in
            ErrorWindowView(errorString: errorString ?? "N/a")
        }

        WindowGroup("Cask Info", for: CaskAdditionalInfo.self) { $info in
            CaskInfoWindowView(info: info ?? .dummy)
        }

        MenuBarExtra(isInserted: $showMenuBarIcon) {
            MenuBarView()
                .environmentObject(caskManager)
        } label: {
            MenuBarIconLabel(
                activeTaskCount: caskManager.activeTasks.count,
                updatesCount: caskManager.outdatedCasks.casks.count
            )
        }
        .menuBarExtraStyle(.window)
    }
}

extension SPUStandardUpdaterController {
    public static let shared = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
}
