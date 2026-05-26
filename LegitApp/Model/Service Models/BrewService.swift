//
//  BrewService.swift
//  LegitApp
//

import Foundation

/// Status of a Homebrew service
enum ServiceStatus: String, Equatable {
    case started
    case stopped
    case error
    case unknown

    var label: String {
        switch self {
        case .started: return "Running"
        case .stopped: return "Stopped"
        case .error:   return "Error"
        case .unknown: return "Unknown"
        }
    }
}

/// Represents a single Homebrew service
struct BrewService: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let status: ServiceStatus
    let user: String?
    let file: String?

    /// Parse a line from `brew services list` output.
    /// Format (tab or space separated):  Name  Status  User  File
    static func parse(line: String) -> BrewService? {
        let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard parts.count >= 2 else { return nil }
        let name = parts[0]
        let statusStr = parts[1].lowercased()
        let status: ServiceStatus
        switch statusStr {
        case "started":  status = .started
        case "stopped":  status = .stopped
        case "none":     status = .stopped   // installed but never configured
        case "error":    status = .error
        default:         status = .unknown
        }
        let user = parts.count >= 3 ? parts[2] : nil
        let file = parts.count >= 4 ? parts[3...].joined(separator: " ") : nil
        return BrewService(name: name, status: status, user: user, file: file)
    }

    /// Parse multiple lines from `brew services list` output (skipping the header)
    static func parseAll(output: String) -> [BrewService] {
        let lines = output.components(separatedBy: "\n")
        return lines.dropFirst().compactMap { parse(line: $0) }
    }

    /// True when this service runs as root (lives in /Library/LaunchDaemons/ or user == "root")
    var isSystemService: Bool {
        if user == "root" { return true }
        guard let file = file else { return false }
        return file.hasPrefix("/Library/LaunchDaemons/")
    }
}

/// Represents an installed Homebrew formula, including formulae that do not provide services.
struct BrewFormula: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let version: String?

    var isVersioned: Bool {
        name.contains("@")
    }

    var binaryDirectory: URL {
        BrewPaths.currentBrewDirectory
            .appendingPathComponent("opt", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
            .appendingPathComponent("bin", isDirectory: true)
    }

    static func parse(line: String) -> BrewFormula? {
        let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard let name = parts.first else { return nil }
        let version = parts.dropFirst().joined(separator: " ")
        return BrewFormula(name: name, version: version.isEmpty ? nil : version)
    }

    static func parseAll(output: String) -> [BrewFormula] {
        output
            .components(separatedBy: .newlines)
            .compactMap { parse(line: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
