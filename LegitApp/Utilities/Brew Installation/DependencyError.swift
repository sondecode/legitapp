//
//  DependencyError.swift
//  LegitApp
//
//  Created by Milán Várady on 2024.12.25.
//

import Foundation

enum DependencyError: LocalizedError {
    case xcodeCommandLineToolsNotInstalled
    case xcodeCommandLineToolsTimeout
    case invalidBrewInstallation

    var errorDescription: String? {
        switch self {
        case .xcodeCommandLineToolsNotInstalled:
            return "Xcode Command Line Tools are not installed."
        case .xcodeCommandLineToolsTimeout:
            return "Couldn't install Xcode Command Line Tools"
        case .invalidBrewInstallation:
            return "The Brew installation seems to be invalid."
        }
    }

    var failureReason: String? {
        switch self {
        case .xcodeCommandLineToolsNotInstalled:
            return "LegitApp cannot run until Xcode Command Line Tools are installed."
        case .xcodeCommandLineToolsTimeout:
            return "Couldn't install Xcode Command Line Tools in a reasonable amount of time"
        case .invalidBrewInstallation:
            return "brew executable is missing or invalid"
        }
    }
}
