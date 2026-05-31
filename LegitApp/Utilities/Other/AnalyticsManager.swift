//
//  AnalyticsManager.swift
//  LegitApp
//
//  Created by Codex on 2026. 05. 24..
//

import Foundation
import OSLog

enum AnalyticsEventName: String, Encodable {
    case appOpen = "app_open"
    case caskInstallSuccess = "cask_install_success"
    case caskUninstallSuccess = "cask_uninstall_success"
    case caskUpdateSuccess = "cask_update_success"
    case caskReinstallSuccess = "cask_reinstall_success"
}

struct AnalyticsManager {
    static let shared = AnalyticsManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LegitApp",
        category: String(describing: AnalyticsManager.self)
    )

    private var defaults: UserDefaults { .standard }

    private var isEnabled: Bool {
        defaults.object(forKey: Preferences.analyticsEnabled.rawValue) as? Bool ?? true
    }

    private var supabaseURL: URL? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "LegitAppSupabaseURL") as? String,
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let url = URL(string: rawValue),
            url.scheme == "https"        // reject non-HTTPS configurations
        else {
            return nil
        }

        return url
    }

    private var supabaseAnonKey: String? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "LegitAppSupabaseAnonKey") as? String,
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return rawValue
    }

    private var anonymousUserID: UUID {
        if
            let rawValue = defaults.string(forKey: Preferences.analyticsAnonymousUserID.rawValue),
            let existingID = UUID(uuidString: rawValue)
        {
            return existingID
        }

        let newID = UUID()
        defaults.set(newID.uuidString, forKey: Preferences.analyticsAnonymousUserID.rawValue)
        return newID
    }

    func trackAppOpenIfNeeded() async {
        guard isEnabled else { return }

        if
            let lastTrackedDate = defaults.object(forKey: Preferences.analyticsLastAppOpenDate.rawValue) as? Date,
            Calendar.current.isDateInToday(lastTrackedDate)
        {
            return
        }

        let didTrack = await track(.appOpen)
        if didTrack {
            defaults.set(Date(), forKey: Preferences.analyticsLastAppOpenDate.rawValue)
        }
    }

    func trackCaskEvent(_ eventName: AnalyticsEventName, cask: Cask) async {
        await track(eventName, cask: cask)
    }

    @discardableResult
    private func track(_ eventName: AnalyticsEventName, cask: Cask? = nil) async -> Bool {
        guard isEnabled else { return false }

        guard let supabaseURL, let supabaseAnonKey else {
            logger.debug("Supabase analytics is enabled but not configured.")
            return false
        }

        // Client-side dedup: skip cask events fired for the same (event, cask) within 60 s.
        // This prevents repeated rapid triggers (e.g. a script looping installs).
        if !isBeyondCooldown(eventName, caskID: cask?.id) {
            logger.debug("Skipping analytics event within cooldown window: \(eventName.rawValue)")
            return false
        }

        let endpoint = supabaseURL.appendingPathComponent("rest/v1/legitapp_events")
        var request = URLRequest(url: endpoint, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let payload = AnalyticsPayload(
            eventName: eventName,
            anonymousUserID: anonymousUserID,
            appVersion: Bundle.main.appVersion,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            caskID: cask?.id,
            caskName: cask?.info.name,
            caskTap: cask?.info.tap,
            installMethod: cask?.info.installMethod.rawValue,
            source: "macos_app"
        )

        do {
            request.httpBody = try JSONEncoder().encode(payload)

            let session = URLSession(configuration: NetworkProxyManager.getURLSessionConfiguration())
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Supabase analytics returned a non-HTTP response.")
                return false
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                logger.error("Supabase analytics failed with status \(httpResponse.statusCode).")
                return false
            }

            recordSent(eventName, caskID: cask?.id)
            return true
        } catch {
            logger.error("Failed to send Supabase analytics event: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Cooldown helpers

    /// Cooldown window for cask events: 60 seconds per (eventName, caskID) pair.
    private static let caskEventCooldown: TimeInterval = 60

    /// UserDefaults key for the last-sent timestamp of a given (event, cask) pair.
    private func cooldownKey(_ eventName: AnalyticsEventName, caskID: String?) -> String {
        "analytics_cooldown_\(eventName.rawValue)_\(caskID ?? "")"
    }

    /// Returns `true` when enough time has passed to send this event again.
    /// `app_open` is managed separately via `analyticsLastAppOpenDate`; skip cooldown for it.
    private func isBeyondCooldown(_ eventName: AnalyticsEventName, caskID: String?) -> Bool {
        guard eventName != .appOpen else { return true }
        let key = cooldownKey(eventName, caskID: caskID)
        guard let lastSent = defaults.object(forKey: key) as? Date else { return true }
        return Date().timeIntervalSince(lastSent) >= Self.caskEventCooldown
    }

    /// Stamps the current time for the given (event, cask) pair.
    private func recordSent(_ eventName: AnalyticsEventName, caskID: String?) {
        guard eventName != .appOpen else { return }
        defaults.set(Date(), forKey: cooldownKey(eventName, caskID: caskID))
    }
}

private struct AnalyticsPayload: Encodable {
    let eventName: AnalyticsEventName
    let anonymousUserID: UUID
    let appVersion: String
    let osVersion: String
    let caskID: String?
    let caskName: String?
    let caskTap: String?
    let installMethod: String?
    let source: String

    enum CodingKeys: String, CodingKey {
        case eventName = "event_name"
        case anonymousUserID = "anonymous_user_id"
        case appVersion = "app_version"
        case osVersion = "os_version"
        case caskID = "cask_id"
        case caskName = "cask_name"
        case caskTap = "cask_tap"
        case installMethod = "install_method"
        case source
    }
}
