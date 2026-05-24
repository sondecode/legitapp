//
//  Shell.swift
//  LegitApp
//
//  Created by Milán Várady on 2024.12.25.
//

import Foundation
import OSLog

/// Namespace for shell command execution utilities
enum Shell {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Shell")

    /// Prefix that the askpass script path must start with (ensures the script is inside the app bundle)
    private static let askpassBundlePrefix: String = Bundle.main.bundlePath

    /// Homebrew can bootstrap its Portable Ruby on first use. Running multiple brew commands during
    /// that bootstrap races on Homebrew's lock and surfaces as a shell failure, so serialize brew only.
    private static let brewCommandLock = BrewCommandLock()

    /// Executes a shell command synchronously
    ///
    /// - Parameters:
    ///   - command: The shell command to run
    ///   - pty: Wether to use pseudo-TTY behavior or not
    ///
    /// - Returns: The output of the shell command
    ///
    /// Using the `pty` option can leave unwanted characters in the output, use only when necessary
    @discardableResult
    static func run(_ command: String, pty: Bool = false) throws -> String {
        let (task, pipe) = try createProcess(command: command, pty: pty)

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        guard let output = String(data: data, encoding: .utf8) else {
            throw ShellError.outputDecodingFailed
        }

        let cleanOutput = output.cleanTerminalOutput()

        guard task.terminationStatus == 0 else {
            throw ShellError.nonZeroExit(
                command: command,
                exitCode: task.terminationStatus,
                output: cleanOutput
            )
        }

        return cleanOutput
    }

    /// Executes a shell command asynchronously
    ///
    /// - Parameters:
    ///   - command: The shell command to run
    ///   - pty: Wether to use pseudo-TTY behavior or not
    ///
    /// - Returns: The output of the shell command
    ///
    /// Using the `pty` option can leave unwanted characters in the output, use only when necessary
    @discardableResult
    static func runAsync(_ command: String, pty: Bool = false) async throws -> String {
        // Simply mark it as async and use the same implementation
        try run(command, pty: pty)
    }

    /// Executes a brew command asynchronously
    ///
    /// - Parameters:
    ///   - command: The shell command to run
    ///   - pty: Wether to use pseudo-TTY behavior or not
    ///
    /// - Returns: The output of the shell command
    ///
    /// Using the `pty` option can leave unwanted characters in the output, use only when necessary
    @discardableResult
    static func runBrewCommand(_ arguments: [String], pty: Bool = false) async throws -> String {
        return try await runBrewCommand(at: BrewPaths.currentBrewExecutable, arguments, pty: pty)
    }

    /// Executes a Homebrew command at a specific executable path.
    ///
    /// Use this instead of calling ``runAsync(_:)`` directly for brew commands so first-run Homebrew
    /// bootstrap steps such as Portable Ruby installation cannot run concurrently.
    @discardableResult
    static func runBrewCommand(at executable: URL, _ arguments: [String], pty: Bool = false) async throws -> String {
        let command = "\(executable.quotedPath()) \(arguments.joined(separator: " "))"
        return try await runSerializedBrewCommand(command, pty: pty)
    }

    /// Executes a raw shell command that invokes Homebrew.
    @discardableResult
    static func runBrewShellCommand(_ command: String, pty: Bool = false) async throws -> String {
        return try await runSerializedBrewCommand(command, pty: pty)
    }

    /// Executes a brew command and streams the output line-by-line.
    static func streamBrewCommand(_ arguments: [String], pty: Bool = false) -> AsyncThrowingStream<String, Error> {
        let command = "\(BrewPaths.currentBrewExecutable.quotedPath()) \(arguments.joined(separator: " "))"
        return streamSerializedBrewCommand(command, pty: pty)
    }

    /// Executes a shell command and streams the output line-by-line
    ///
    /// - Parameters:
    ///   - command: The shell command to run
    ///   - pty: Wether to use pseudo-TTY behavior or not
    ///
    /// - Returns: An ``AsyncThrowingStream`` that yields the output in real time
    ///
    /// Using the `pty` option can leave unwanted characters in the output, use only when necessary
    static func stream(_ command: String, pty: Bool = false) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let (task, pipe) = try createProcess(command: command, pty: pty)
                    let fileHandle = pipe.fileHandleForReading

                    try task.run()

                    for try await line in fileHandle.bytes.lines {
                        let cleanOutput = line.cleanTerminalOutput()
                        continuation.yield(cleanOutput)
                    }

                    task.waitUntilExit()

                    if task.terminationStatus != 0 {
                        continuation.finish(
                            throwing: ShellError.nonZeroExit(
                                command: command,
                                exitCode: task.terminationStatus,
                                output: "n/a (streamed output)"
                            )
                        )
                    } else {
                        continuation.finish()
                    }
                } catch {
                    logger.error("Stream error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    @discardableResult
    private static func runSerializedBrewCommand(_ command: String, pty: Bool) async throws -> String {
        var attempt = 0

        while true {
            await brewCommandLock.lock()
            do {
                let output = try run(command, pty: pty)
                await brewCommandLock.unlock()
                return output
            } catch {
                await brewCommandLock.unlock()

                guard isTransientHomebrewLockError(error), attempt < 5 else {
                    throw error
                }

                attempt += 1
                logger.notice("Homebrew is busy bootstrapping, retrying command. Attempt: \(attempt)")
                try await Task.sleep(for: .seconds(2))
            }
        }
    }

    private static func streamSerializedBrewCommand(_ command: String, pty: Bool) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var attempt = 0

                while true {
                    await brewCommandLock.lock()
                    do {
                        try await streamBrewCommandOnce(command, pty: pty, continuation: continuation)
                        await brewCommandLock.unlock()
                        continuation.finish()
                        return
                    } catch {
                        await brewCommandLock.unlock()

                        guard isTransientHomebrewLockError(error), attempt < 5 else {
                            logger.error("Stream error: \(error.localizedDescription)")
                            continuation.finish(throwing: error)
                            return
                        }

                        attempt += 1
                        logger.notice("Homebrew is busy bootstrapping, retrying streamed command. Attempt: \(attempt)")
                        try await Task.sleep(for: .seconds(2))
                    }
                }
            }
        }
    }

    private static func streamBrewCommandOnce(
        _ command: String,
        pty: Bool,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let (task, pipe) = try createProcess(command: command, pty: pty)
        let fileHandle = pipe.fileHandleForReading
        var output = ""

        try task.run()

        for try await line in fileHandle.bytes.lines {
            let cleanOutput = line.cleanTerminalOutput()
            output += cleanOutput + "\n"
            continuation.yield(cleanOutput)
        }

        task.waitUntilExit()

        if task.terminationStatus != 0 {
            throw ShellError.nonZeroExit(
                command: command,
                exitCode: task.terminationStatus,
                output: output.isEmpty ? "n/a (streamed output)" : output
            )
        }
    }

    private static func isTransientHomebrewLockError(_ error: Error) -> Bool {
        guard case ShellError.nonZeroExit(_, _, let output) = error else {
            return false
        }

        return output.contains("already locked")
            || output.contains("Another `brew vendor-install ruby` process is already running")
    }

    private actor BrewCommandLock {
        private var isLocked = false
        private var waiters: [CheckedContinuation<Void, Never>] = []

        func lock() async {
            if !isLocked {
                isLocked = true
                return
            }

            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }

        func unlock() {
            if waiters.isEmpty {
                isLocked = false
            } else {
                waiters.removeFirst().resume()
            }
        }
    }

    /// Initializes a shell process with a given command
    ///
    /// - Parameters:
    ///   - command: The shell command to run
    ///   - pty: Wether to use pseudo-TTY behavior or not
    ///
    /// - Returns: The initialized ``Process`` and ``Pipe`` object
    ///
    /// We need the `pty` option because some brew commands run in quiet mode if it detects its not in a interactive environment
    private static func createProcess(command: String, pty: Bool) throws -> (Process, Pipe) {
        // Verify askpass script
        guard let scriptPath = Bundle.main.path(forResource: "askpass", ofType: "js") else {
            throw ShellError.askpassNotFound
        }

        // Verify the script is inside the app bundle to prevent path hijacking
        guard scriptPath.hasPrefix(askpassBundlePrefix) else {
            throw ShellError.askpassChecksumMismatch
        }

        guard let homeDirectory = ProcessInfo.processInfo.environment["HOME"] else {
            throw ShellError.coundtGetHomeDirectory
        }

        let task = Process()
        let pipe = Pipe()

        // Set up environment
        var environment: [String: String] = [
            "SUDO_ASKPASS": scriptPath,
            "TERM": "xterm-256color", // Ensure terminal emulation
            "HOME": homeDirectory
        ]

        if let proxySettings = try? NetworkProxyManager.getSystemProxySettings() {
            logger.info("Network proxy is enabled. Type: \(proxySettings.type.rawValue)")
            environment["ALL_PROXY"] = proxySettings.fullString
        }

        if let mirrorEnvironmentVariables = MirrorEnvironment.getEnvironmentVariables() {
            logger.info("Mirror enabled. API domain: \(mirrorEnvironmentVariables["HOMEBREW_API_DOMAIN"] ?? "not set")")
            environment.merge(mirrorEnvironmentVariables) { (_, new) in new }
        }

        task.standardOutput = pipe
        task.standardError = pipe
        task.environment = environment

        if pty {
            // Use `script` for pseudo-TTY behavior
            task.executableURL = URL(fileURLWithPath: "/usr/bin/script")
            task.arguments = ["-q", "/dev/null", "/bin/sh", "-c", command]
        } else {
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", command]
        }

        return (task, pipe)
    }
}
