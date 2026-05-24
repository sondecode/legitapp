//
//  AppDelegate.swift
//  LegitApp
//
//  Created by Milán Várady on 2025.01.01.
//

import Foundation
import AppKit

class ApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set default value for keepRunningInMenuBar to true if not set
        if UserDefaults.standard.object(forKey: Preferences.keepRunningInMenuBar.rawValue) == nil {
            UserDefaults.standard.set(true, forKey: Preferences.keepRunningInMenuBar.rawValue)
        }
    }

    // Only keep the app alive after window close if the menu bar icon is enabled
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let keepRunning = UserDefaults.standard.bool(forKey: Preferences.keepRunningInMenuBar.rawValue)
        return !keepRunning
    }
}
