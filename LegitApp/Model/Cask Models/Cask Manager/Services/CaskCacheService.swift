//
//  CaskCacheService.swift
//  LegitApp
//
//  Created by Milán Várady on 2025.05.09.
//

import Foundation
import OSLog

/// Responsible for managing cache operations for cask data
struct CaskCacheService {
    private static let cacheDirectory = URL.cachesDirectory
        .appendingPathComponent("LegitApp", conformingTo: .directory)

    static let caskCacheURL = URL.cachesDirectory
        .appendingPathComponent("LegitApp", conformingTo: .directory)
        .appendingPathComponent("cask.json", conformingTo: .json)

    static let analyticsCacheURL = URL.cachesDirectory
        .appendingPathComponent("LegitApp", conformingTo: .directory)
        .appendingPathComponent("caskAnalytics.json", conformingTo: .json)

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CaskCacheService.self)
    )

    /// Loads a model with caching strategy (tries cache first if appropriate, falls back to network)
    /// - Parameters:
    ///   - networkFetch: Closure to fetch data from network
    ///   - cacheURL: URL where cached data is stored
    ///   - type: Type to decode into
    /// - Returns: Decoded object of specified type
    func loadModelWithCaching<T: Decodable>(
        networkFetch: @escaping () async throws -> (Data, T),
        cacheURL: URL,
        as type: T.Type
    ) async throws -> T {
        // Try to load from cache if it's fresh enough
        do {
            if try shouldLoadFromCache(url: cacheURL) {
                logger.notice("Cache for \(type) is up to date")
                return try await loadFromCache(from: cacheURL, as: type)
            }
        } catch {
            logger.error("Failed to load \(type) from cache: \(error.localizedDescription)")
            logger.notice("Will try to fetch from network")
        }

        // Load from network
        do {
            let (data, model) = try await networkFetch()

            // Cache the data
            await saveToCache(data: data, at: cacheURL)

            return model
        } catch {
            logger.error("Failed to fetch \(type) from network: \(error.localizedDescription)")

            // Try to load from cache as fallback
            logger.notice("Attempting to load from cache as fallback")
            return try await loadFromCache(from: cacheURL, as: type)
        }
    }

    /// Loads cached data without checking freshness.
    ///
    /// Used for fast startup: stale catalog data is still much better than an empty main screen,
    /// and a background refresh can replace it shortly after launch.
    func loadCachedModelIfAvailable<T: Decodable>(from cacheURL: URL, as type: T.Type) async throws -> T {
        return try await loadFromCache(from: cacheURL, as: type)
    }

    /// Determines if data should be loaded from cache based on update frequency settings
    /// - Parameter url: URL of the cache file to check
    /// - Returns: True if cache is fresh enough to be used
    private func shouldLoadFromCache(url: URL) throws -> Bool {
        let defaults = UserDefaults.standard
        let updateFreqRawValue: Int

        if defaults.object(forKey: Preferences.catalogUpdateFrequency.rawValue) == nil {
            updateFreqRawValue = CatalogUpdateFrequency.weekly.rawValue
        } else {
            updateFreqRawValue = defaults.integer(forKey: Preferences.catalogUpdateFrequency.rawValue)
        }

        guard let updateFreq = CatalogUpdateFrequency(rawValue: updateFreqRawValue) else {
            throw CaskLoadError.failedToGetUpdateFrequency
        }

        return try updateFreq.shouldLoadFromCache(at: url)
    }

    /// Loads and decodes a model from cache
    /// - Parameters:
    ///   - url: URL of the cache file
    ///   - type: Type to decode into
    /// - Returns: Decoded object of specified type
    private func loadFromCache<T: Decodable>(from url: URL, as type: T.Type) async throws -> T {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(type, from: data)
        logger.info("Loaded \(String(describing: type)) from cache at \(url.path)")
        return decoded
    }

    /// Saves data to cache
    /// - Parameters:
    ///   - data: Data to save
    ///   - url: URL to save to
    private func saveToCache(data: Data, at url: URL) async {
        // Create cache directory if doesn't exist
        do {
            var isDirectory: ObjCBool = true

            if !FileManager.default.fileExists(atPath: Self.cacheDirectory.path, isDirectory: &isDirectory) {
                logger.warning("Cache directory doesn't exist, attempting to create it")
                try FileManager.default.createDirectory(at: Self.cacheDirectory, withIntermediateDirectories: true)
            }
        } catch {
            logger.error("Couldn't create cache directory: \(error.localizedDescription)")
            return
        }

        // Save data to cache
        do {
            try data.write(to: url)
            logger.notice("Successfully saved data to cache at \(url.path)")
        } catch {
            logger.error("Couldn't write data to cache: \(error.localizedDescription)")
        }
    }
}
