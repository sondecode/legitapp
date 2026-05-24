//
//  SettingsView+GeneralSettings.swift
//  LegitApp
//
//  Created by Milán Várady on 2024.12.26.
//

import SwiftUI
import AppKit

extension SettingsView {
    struct GeneralSettingsView: View {
        @AppStorage(Preferences.colorSchemePreference.rawValue) var colorSchemePreference: ColorSchemePreference = .system
        @AppStorage(Preferences.catalogUpdateFrequency.rawValue) var catalogUpdateFrequency: CatalogUpdateFrequency = .weekly
        @AppStorage(Preferences.notificationSuccess.rawValue) var notificationOnSuccess: Bool = false
        @AppStorage(Preferences.notificationFailure.rawValue) var notificationOnFailure: Bool = true
        @AppStorage(Preferences.analyticsEnabled.rawValue) var analyticsEnabled: Bool = true
        @AppStorage(Preferences.showMenuBarIcon.rawValue) var showMenuBarIcon: Bool = true
        @AppStorage(Preferences.keepRunningInMenuBar.rawValue) var keepRunningInMenuBar: Bool = false

        /// Needed for a workaround for changing the color scheme
        @State var fixingColor = false

        @State private var selectedLanguage: AppLanguage = .selected
        @State private var showRestartAlert = false

        var body: some View {
            VStack(alignment: .leading) {
                Text("Appearance", comment: "Appearnace settings title")
                    .bold()

                Picker("Color Scheme:", selection: $colorSchemePreference) {
                    ForEach(ColorSchemePreference.allCases) { color in
                        Text(color.description)
                    }
                }
                .pickerStyle(.segmented)

                Divider()
                    .padding(.vertical)

                Text("Language", comment: "Language settings title")
                    .bold()

                Picker("Language:", selection: $selectedLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .onChange(of: selectedLanguage) { _, newValue in
                    AppLanguage.apply(newValue)
                    showRestartAlert = true
                }
                .alert("Restart Required", isPresented: $showRestartAlert) {
                    Button("Restart Now") {
                        AppLanguage.relaunch()
                    }
                    Button("Later", role: .cancel) { }
                } message: {
                    Text("Please restart the app to apply the language change.")
                }

                Divider()
                    .padding(.vertical)

                Text("App Catalog", comment: "Catalog settings title")
                    .bold()

                Picker("Fetch app catalog every:", selection: $catalogUpdateFrequency) {
                    ForEach(CatalogUpdateFrequency.allCases) { freq in
                        Text(freq.description)
                    }
                }

                Divider()
                    .padding(.vertical)

                Text("Notifications", comment: "Notification settings title")
                    .bold()

                Toggle("Task completions", isOn: $notificationOnSuccess)
                Toggle("Task errors", isOn: $notificationOnFailure)

                Divider()
                    .padding(.vertical)

                Text("Analytics", comment: "Analytics settings title")
                    .bold()

                Toggle("Send security and usage logs", isOn: $analyticsEnabled)
                Text("LegitApp sends minimal anonymous logs to count app opens, successful install, uninstall, update actions, and help limit spam. No personal data or full installed app list is sent.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()
                    .padding(.vertical)

                Text("Menu Bar", comment: "Menu bar settings title")
                    .bold()

                Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
                Toggle("Keep running when window is closed", isOn: $keepRunningInMenuBar)
                    .disabled(!showMenuBarIcon)
                    .onChange(of: showMenuBarIcon) { _, enabled in
                        if !enabled { keepRunningInMenuBar = false }
                    }
            }
            .padding()
            .onChange(of: colorSchemePreference) { _, newValue in
                // Don't remove this!
                // This is here because changing the .preferredColorScheme view modifier is bugged
                // When it's set back to nil, parts of the UI don't default back to the system color scheme
                if newValue == .system && !fixingColor {
                    // Set fixingColor to true, so we don't recursively call this function
                    self.fixingColor = true

                    // Get system color scheme
                    let darkMode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"

                    Task {
                        // Set color scheme to system
                        colorSchemePreference = darkMode ? .dark : .light
                        // Wait
                        try? await Task.sleep(for: .seconds(0.1))
                        // Set it back to nil (.system)
                        colorSchemePreference = .system
                        // Wait
                        try? await Task.sleep(for: .seconds(0.1))
                        // Set fixing color back to false
                        await MainActor.run { self.fixingColor = false }
                    }
                }
            }
        }
    }
}
