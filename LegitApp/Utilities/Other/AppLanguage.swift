//
//  AppLanguage.swift
//  LegitApp
//

import Foundation
import AppKit

enum AppLanguage: String, CaseIterable, Identifiable {
    case vi
    case en
    case fr

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vi: return "Tiếng Việt"
        case .en: return "English"
        case .fr: return "Français"
        }
    }

    static let defaultLanguage: AppLanguage = .vi

    static var selected: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: Preferences.appLanguageCode.rawValue)
            ?? UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first
            ?? defaultLanguage.rawValue
        let code = String(rawValue.prefix(2))
        return AppLanguage(rawValue: code) ?? defaultLanguage
    }

    static func ensureDefaultLanguageForFirstLaunch() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Preferences.appLanguageSelected.rawValue) == nil else {
            return
        }

        apply(defaultLanguage, markSelected: false)
    }

    static func apply(_ language: AppLanguage, markSelected: Bool = true) {
        let defaults = UserDefaults.standard
        defaults.set(language.rawValue, forKey: Preferences.appLanguageCode.rawValue)
        defaults.set([language.rawValue], forKey: "AppleLanguages")

        if markSelected {
            defaults.set(true, forKey: Preferences.appLanguageSelected.rawValue)
        }

        defaults.synchronize()
    }

    @MainActor
    static func relaunch() {
        let url = Bundle.main.bundleURL
        NSWorkspace.shared.open(url)
        NSApplication.shared.terminate(nil)
    }
}
