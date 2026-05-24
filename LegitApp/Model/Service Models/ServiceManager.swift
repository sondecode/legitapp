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
    @Published var isLoading: Bool = false
    @Published var activeTasks: Set<String> = []

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
            if reloadAfterCompletion {
                await loadServices()
            }
        } catch {
            logger.error("Service command \(args.joined(separator: " ")) failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Install Formula

    func installAndStart(formula: String) async {
        activeTasks.insert(formula)
        defer { activeTasks.remove(formula) }
        do {
            // Install as formula (not cask)
            try await Shell.runBrewCommand(["install", formula])
            try await Shell.runBrewCommand(["services", "start", formula])
            await loadServices()
        } catch {
            logger.error("Install formula \(formula) failed: \(error.localizedDescription)")
        }
    }
}
