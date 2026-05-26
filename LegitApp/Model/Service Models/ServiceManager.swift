//
//  ServiceManager.swift
//  LegitApp
//

import Foundation
import OSLog

@MainActor
final class ServiceManager: ObservableObject {
    static let shared = ServiceManager()

    @Published var services: [BrewService] = []
    @Published var installedFormulae: [BrewFormula] = []
    @Published var isLoading: Bool = false
    @Published var activeTasks: Set<String> = []
    @Published var alert = AlertManager()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ServiceManager")

    private init() {}

    // MARK: - Load

    func loadServices() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let output = try await Shell.runBrewCommand(["services", "list"])
            services = BrewService.parseAll(output: output)
        } catch {
            logger.error("Failed to load services: \(error.localizedDescription)")
        }
    }

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }

        async let servicesOutput = Shell.runBrewCommand(["services", "list"])
        async let formulaeOutput = Shell.runBrewCommand(["list", "--formula", "--versions"])

        do {
            let output = try await servicesOutput
            services = BrewService.parseAll(output: output)
        } catch {
            logger.error("Failed to load services: \(error.localizedDescription)")
        }

        do {
            let output = try await formulaeOutput
            installedFormulae = BrewFormula.parseAll(output: output)
        } catch {
            logger.error("Failed to load installed formulae: \(error.localizedDescription)")
        }
    }

    // MARK: - Control

    func start(service: BrewService) async {
        await runServiceCommand(["services", "start", service.name], service: service)
    }

    func stop(service: BrewService) async {
        await runServiceCommand(["services", "stop", service.name], service: service)
    }

    func restart(service: BrewService) async {
        await runServiceCommand(["services", "restart", service.name], service: service)
    }

    func uninstall(service: BrewService) async {
        activeTasks.insert(service.name)
        defer { activeTasks.remove(service.name) }

        do {
            if service.status == .started || service.status == .error {
                try await runServiceCommandWithoutTracking(["services", "stop", service.name], service: service)
            }

            try await Shell.runBrewCommand(["uninstall", service.name])
            await loadAll()
        } catch {
            logger.error("Uninstall service \(service.name) failed: \(error.localizedDescription)")
            alert.show(title: "Failed to uninstall formula", message: error.localizedDescription)
        }
    }

    func uninstall(formula: BrewFormula) async {
        activeTasks.insert(formula.name)
        defer { activeTasks.remove(formula.name) }

        do {
            if let service = services.first(where: { $0.name == formula.name }),
               service.status == .started || service.status == .error {
                try await runServiceCommandWithoutTracking(["services", "stop", service.name], service: service)
            }

            try await Shell.runBrewCommand(["uninstall", formula.name])
            await loadAll()
        } catch {
            logger.error("Uninstall formula \(formula.name) failed: \(error.localizedDescription)")
            alert.show(title: "Failed to uninstall formula", message: error.localizedDescription)
        }
    }

    func setDefaultVersion(formula: BrewFormula) async {
        guard formula.isVersioned else { return }

        activeTasks.insert(formula.name)
        defer { activeTasks.remove(formula.name) }

        do {
            try updateShellProfiles(for: formula)
            alert.show(
                title: "Default version updated",
                message: String(
                    localized: "\(formula.name) was added to your zsh profile. Open a new Terminal window or run source ~/.zprofile to use it."
                )
            )
        } catch {
            logger.error("Set default formula version \(formula.name) failed: \(error.localizedDescription)")
            alert.show(title: "Failed to set default version", message: error.localizedDescription)
        }
    }

    func startAll() async {
        let servicesToStart = services.filter { $0.status == .stopped || $0.status == .unknown }
        await runBulkServiceCommand("start", services: servicesToStart)
    }

    func stopAll() async {
        let servicesToStop = services.filter { $0.status == .started || $0.status == .error }
        await runBulkServiceCommand("stop", services: servicesToStop)
    }

    private func runBulkServiceCommand(_ action: String, services: [BrewService]) async {
        guard !services.isEmpty else {
            return
        }

        for service in services {
            await runServiceCommand(["services", action, service.name], service: service, reloadAfterCompletion: false)
        }

        await loadServices()
    }

    private func runServiceCommand(_ args: [String], service: BrewService, reloadAfterCompletion: Bool = true) async {
        activeTasks.insert(service.name)
        defer { activeTasks.remove(service.name) }
        do {
            try await runServiceCommandWithoutTracking(args, service: service)
            if reloadAfterCompletion {
                await loadServices()
            }
        } catch {
            logger.error("Service command \(args.joined(separator: " ")) failed: \(error.localizedDescription)")
        }
    }

    private func runServiceCommandWithoutTracking(_ args: [String], service: BrewService) async throws {
        let brewPath = BrewPaths.currentBrewExecutable.quotedPath()
        let brewArgs = args.joined(separator: " ")
        // Suppress brew auto-update for faster service operations
        let envPrefix = "env HOMEBREW_NO_AUTO_UPDATE=1"
        let command: String
        if service.isSystemService {
            // System services (LaunchDaemons / root user) require sudo -A
            // SUDO_ASKPASS is set by Shell.createProcess so this prompts via osascript
            command = "sudo -A \(envPrefix) \(brewPath) \(brewArgs)"
        } else {
            command = "\(envPrefix) \(brewPath) \(brewArgs)"
        }
        try await Shell.runBrewShellCommand(command)
    }

    private func updateShellProfiles(for formula: BrewFormula) throws {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let profiles = [
            homeDirectory.appendingPathComponent(".zprofile"),
            homeDirectory.appendingPathComponent(".zshrc")
        ]

        for profile in profiles {
            try updateShellProfile(profile, formula: formula)
        }
    }

    private func updateShellProfile(_ profile: URL, formula: BrewFormula) throws {
        let beginMarker = "# >>> LegitApp Homebrew default formula >>>"
        let endMarker = "# <<< LegitApp Homebrew default formula <<<"
        let path = formula.binaryDirectory.path(percentEncoded: false)
        let block = """

        \(beginMarker)
        # Managed by LegitApp. Move \(formula.name) ahead of other Homebrew versions.
        export PATH="\(path):$PATH"
        \(endMarker)
        """

        let existingContent: String
        if FileManager.default.fileExists(atPath: profile.path(percentEncoded: false)) {
            existingContent = try String(contentsOf: profile, encoding: .utf8)
        } else {
            existingContent = ""
        }

        let updatedContent: String
        if let beginRange = existingContent.range(of: beginMarker),
           let endRange = existingContent.range(of: endMarker, range: beginRange.upperBound..<existingContent.endIndex) {
            let managedRange = beginRange.lowerBound..<endRange.upperBound
            updatedContent = existingContent.replacingCharacters(in: managedRange, with: block.trimmingCharacters(in: .newlines))
        } else {
            updatedContent = existingContent.trimmingCharacters(in: .newlines) + block
        }

        try updatedContent.appending("\n").write(to: profile, atomically: true, encoding: .utf8)
    }

    // MARK: - Install Formula

    @discardableResult
    func installAndStart(formula: String) async -> Bool {
        activeTasks.insert(formula)
        defer { activeTasks.remove(formula) }
        do {
            // Install as formula (not cask)
            try await Shell.runBrewCommand(["install", formula])
            try await Shell.runBrewCommand(["services", "start", formula])
            await loadAll()
            return true
        } catch {
            logger.error("Install formula \(formula) failed: \(error.localizedDescription)")
            alert.show(
                title: "Failed to install service",
                message: serviceInstallFailureMessage(formula: formula, error: error)
            )
            return false
        }
    }

    private func serviceInstallFailureMessage(formula: String, error: Error) -> String {
        guard case ShellError.nonZeroExit(_, _, let output) = error else {
            return error.localizedDescription
        }

        if output.contains("No available formula with the name") {
            let suggestions = extractHomebrewSuggestions(from: output)
            if suggestions.isEmpty {
                return String(localized: "No Homebrew formula named \(formula) was found. Please check the formula name and try again.")
            }

            return String(
                localized: "No Homebrew formula named \(formula) was found. Did you mean: \(suggestions.joined(separator: ", "))?"
            )
        }

        if output.contains("has not implemented #plist, #service or provided a locatable service file") {
            return String(localized: "\(formula) was installed, but it does not provide a Homebrew service to start. It will not appear in Services.")
        }

        return error.localizedDescription
    }

    private func extractHomebrewSuggestions(from output: String) -> [String] {
        let lines = output.components(separatedBy: .newlines)
        var suggestions: [String] = []
        var isReadingSuggestions = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.hasPrefix("==> Formulae") || trimmedLine.hasPrefix("==> Casks") {
                isReadingSuggestions = true
                continue
            }

            if trimmedLine.hasPrefix("To install ") {
                break
            }

            guard isReadingSuggestions, !trimmedLine.isEmpty, !trimmedLine.hasPrefix("==>") else {
                continue
            }

            suggestions.append(contentsOf: trimmedLine.split(separator: " ").map(String.init))
        }

        return Array(Set(suggestions)).sorted()
    }
}
