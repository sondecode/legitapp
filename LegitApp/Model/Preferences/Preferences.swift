//
//  Preferences.swift
//  LegitApp
//
//  Created by Milán Várady on 2023. 08. 18..
//

import Foundation

enum Preferences: String {
    // Setup
    case setupComplete
    case appLanguageSelected
    case appLanguageCode

    // General
    case colorSchemePreference
    case catalogUpdateFrequency
    case notificationSuccess
    case notificationFailure
    case analyticsEnabled
    case analyticsAnonymousUserID
    case analyticsLastAppOpenDate

    // Brew
    case brewPathOption
    case customUserBrewPath
    case includeCasksFromTaps
    case appdirOn
    case appdirPath
    case greedyUpgrade
    case noQuarantine

    // Proxy
    case networkProxyEnabled
    case preferredProxyType

    // Mirrors
    case mirrorEnabled
    case mirrorAPIDomain
    case mirrorBrewGitRemote
    case mirrorCoreGitRemote
    case mirrorBottleDomain

    // Sorting options
    case searchSortOption
    case hideUnpopularApps
    case hideDisabledApps

    // Menu bar
    case showMenuBarIcon
    case keepRunningInMenuBar

    // Banner
    case firstLaunchDate
}
