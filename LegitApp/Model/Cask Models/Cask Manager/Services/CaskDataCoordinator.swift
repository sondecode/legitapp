//
//  CaskDataCoordinator.swift
//  LegitApp
//
//  Created by Milán Várady on 2025.05.09.
//

import Foundation
import OSLog

/// Coordinates the loading and processing of cask data using various services
@MainActor
final class CaskDataCoordinator {
    private let networkService: CaskNetworkService
    private let cacheService: CaskCacheService
    private let installedService: InstalledCaskService
    private let modelBuilder: CaskModelBuilder

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CaskDataCoordinator.self)
    )

    init(
        networkService: CaskNetworkService = CaskNetworkService(),
        cacheService: CaskCacheService = CaskCacheService(),
        installedService: InstalledCaskService = InstalledCaskService(),
        modelBuilder: CaskModelBuilder = CaskModelBuilder()
    ) {
        self.networkService = networkService
        self.cacheService = cacheService
        self.installedService = installedService
        self.modelBuilder = modelBuilder
    }

    /// Loads all cask data and builds the necessary models
    /// - Returns: Complete cask data including models and collections
    func loadAllCaskData(preferCachedCatalog: Bool = false, includeDeferredData: Bool = true) async throws -> CaskDataResult {
        logger.info("Starting to load cask data")

        // Load data concurrently
        async let catalogData = try await loadCatalogData()
        async let caskInfo = loadCaskInfo(preferStaleCache: preferCachedCatalog)
        async let tapCaskInfo = loadTapCaskInfoIfNeeded(includeDeferredData)
        async let analytics = loadAnalyticsData(preferStaleCache: preferCachedCatalog)
        async let installedCasks = getInstalledCasks()
        async let outdatedCasks = getOutdatedCasksIfNeeded(includeDeferredData)

        // Wait for all async operations to complete
        let (catalogResult, caskInfoResult, tapCaskInfoResult, analyticsResult, installedCasksResult, outdatedCasksResult) =
        try await (catalogData, caskInfo, tapCaskInfo, analytics, installedCasks, outdatedCasks)
        let categoriesResult = catalogResult.categories
        let bannerConfig = catalogResult.banner

        // Combine cask info from main repository and taps
        let combinedCaskInfo = caskInfoResult + tapCaskInfoResult

        // Create analytics dictionary
        let analyticsDict = await modelBuilder.createAnalyticsDictionary(from: analyticsResult)

        // Build cask models
        logger.info("Building cask models")
        let compiledCaskModels = try await modelBuilder.createCaskModels(
            from: combinedCaskInfo,
            installedCasks: installedCasksResult,
            outdatedCasks: outdatedCasksResult,
            analyticsDict: analyticsDict,
            categories: categoriesResult
        )

        // Create category view models
        logger.info("Creating category view models")
        let categoryViewModels = await modelBuilder.createCategoryViewModels(
            from: categoriesResult,
            using: compiledCaskModels
        )

        // Create tap view models
        logger.info("Creating tap view models")
        let tapViewModels = modelBuilder.createTapViewModels(
            using: compiledCaskModels
        )

        // Create searchable collections
        let allCasksCollection = SearchableCaskCollection(casks: compiledCaskModels.allCasksList)
        let installedCasksCollection = SearchableCaskCollection(casks: compiledCaskModels.installedCasks.sorted())
        let outdatedCasksCollection = SearchableCaskCollection(casks: compiledCaskModels.outdatedCasks.sorted())

        logger.info("Cask data loading completed successfully")

        // Return result
        return CaskDataResult(
            allCasks: compiledCaskModels.allCasksDict,
            allCasksCollection: allCasksCollection,
            installedCasksCollection: installedCasksCollection,
            outdatedCasksCollection: outdatedCasksCollection,
            categories: categoryViewModels,
            taps: tapViewModels,
            bannerConfig: bannerConfig
        )
    }

    /// Gets the set of outdated casks
    func getOutdatedCasks() async throws -> Set<CaskId> {
        return try await installedService.getOutdatedCasks()
    }

    /// Loads cask information with caching strategy
    private func loadCaskInfo(preferStaleCache: Bool) async throws -> [CaskInfo] {
        if preferStaleCache,
           let cached = try? await cacheService.loadCachedModelIfAvailable(
            from: CaskCacheService.caskCacheURL,
            as: [CaskInfo].self
           ) {
            logger.info("Loaded cask info from startup cache")
            return cached
        }

        return try await cacheService.loadModelWithCaching(
            networkFetch: { @Sendable in
                let data = try await self.networkService.fetchCaskInfo()
                return (try JSONEncoder().encode(data), data)
            },
            cacheURL: CaskCacheService.caskCacheURL,
            as: [CaskInfo].self
        )
    }

    /// Loads tap cask information
    private func loadTapCaskInfo() async -> [CaskInfo] {
        return await networkService.fetchTapCaskInfo()
    }

    private func loadTapCaskInfoIfNeeded(_ enabled: Bool) async -> [CaskInfo] {
        guard enabled else {
            return []
        }

        return await loadTapCaskInfo()
    }

    /// Loads analytics data with caching strategy
    private func loadAnalyticsData(preferStaleCache: Bool) async throws -> BrewAnalytics {
        if preferStaleCache,
           let cached = try? await cacheService.loadCachedModelIfAvailable(
            from: CaskCacheService.analyticsCacheURL,
            as: BrewAnalytics.self
           ) {
            logger.info("Loaded analytics from startup cache")
            return cached
        }

        return try await cacheService.loadModelWithCaching(
            networkFetch: { @Sendable in
                let data = try await self.networkService.fetchAnalyticsData()
                return (try JSONEncoder().encode(data), data)
            },
            cacheURL: CaskCacheService.analyticsCacheURL,
            as: BrewAnalytics.self
        )
    }

    /// Gets the set of installed casks
    private func getInstalledCasks() async throws -> Set<CaskId> {
        return try await installedService.getInstalledCasks()
    }

    private func getOutdatedCasksIfNeeded(_ enabled: Bool) async throws -> Set<CaskId> {
        guard enabled else {
            return []
        }

        return try await getOutdatedCasks()
    }

    private static let categoriesCacheURL = URL.cachesDirectory
        .appendingPathComponent("LegitApp", conformingTo: .directory)
        .appendingPathComponent("categories_remote.json", conformingTo: .json)

    /// Loads catalog data (banner + categories) — tries Supabase first, then remote JSON/cache/bundle.
    private func loadCatalogData() async throws -> CatalogData {
        let decoder = JSONDecoder()
        func decode(_ data: Data) throws -> CatalogData {
            // Support both the new wrapped format {banner, categories} and legacy plain array
            if let catalog = try? decoder.decode(CatalogData.self, from: data) {
                return catalog
            }
            let categories = try decoder.decode([Category].self, from: data)
            return CatalogData(banner: nil, categories: categories)
        }

        // 1. Try Supabase database catalog.
        do {
            if let catalog = try await loadCatalogDataFromDatabase() {
                try? cacheCatalogData(catalog)
                logger.info("Loaded catalog from Supabase")
                return catalog
            }
        } catch {
            logger.warning("Supabase catalog fetch failed: \(error.localizedDescription)")
        }

        #if DEBUG
        // In debug fallback, use bundled local JSON to keep iteration deterministic when Supabase is unavailable.
        if let url = Bundle.main.url(forResource: "categories", withExtension: "json") {
            let data = try Data(contentsOf: url)
            return try decode(data)
        }
        #endif

        // 2. Try remote URL from Info.plist.
        if let urlString = Bundle.main.infoDictionary?["LegitAppCategoriesURL"] as? String,
           let remoteURL = URL(string: urlString) {
            do {
                var request = URLRequest(url: remoteURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 6)
                request.setValue("LegitApp/\(Bundle.main.appVersion)", forHTTPHeaderField: "User-Agent")
                let (data, _) = try await URLSession.shared.data(for: request)
                let catalog = try decode(data)
                // Cache for offline use
                let cacheDir = Self.categoriesCacheURL.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
                try? data.write(to: Self.categoriesCacheURL)
                logger.info("Loaded catalog from remote")
                return catalog
            } catch {
                logger.warning("Remote categories fetch failed: \(error.localizedDescription)")
            }
        }

        // 3. Fallback: cached remote version.
        if FileManager.default.fileExists(atPath: Self.categoriesCacheURL.path),
           let data = try? Data(contentsOf: Self.categoriesCacheURL),
           let catalog = try? decode(data) {
            logger.info("Loaded catalog from disk cache")
            return catalog
        }

        // 4. Fallback: bundle (always available).
        guard let url = Bundle.main.url(forResource: "categories", withExtension: "json") else {
            throw CaskLoadError.failedToLoadCategoryJSON
        }
        logger.info("Loaded catalog from bundle")
        let data = try Data(contentsOf: url)
        return try decode(data)
    }

    private func cacheCatalogData(_ catalog: CatalogData) throws {
        let cacheDir = Self.categoriesCacheURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(catalog)
        try data.write(to: Self.categoriesCacheURL)
    }

    private func loadCatalogDataFromDatabase() async throws -> CatalogData? {
        guard
            let supabaseURL = supabaseURL,
            let supabaseAnonKey = supabaseAnonKey
        else {
            return nil
        }

        var components = URLComponents(url: supabaseURL.appendingPathComponent("rest/v1/legitapp_catalog"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "select", value: "data"),
            URLQueryItem(name: "limit", value: "1")
        ]

        guard let endpoint = components?.url else {
            return nil
        }

        var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 6)
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("LegitApp/\(Bundle.main.appVersion)", forHTTPHeaderField: "User-Agent")

        let session = URLSession(configuration: NetworkProxyManager.getURLSessionConfiguration())
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            logger.warning("Supabase catalog returned status \(httpResponse.statusCode).")
            return nil
        }

        let rows = try JSONDecoder().decode([SupabaseCatalogRow].self, from: data)
        return rows.first?.data
    }

    private var supabaseURL: URL? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "LegitAppSupabaseURL") as? String,
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return URL(string: rawValue)
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
}

private struct SupabaseCatalogRow: Decodable {
    let data: CatalogData
}

/// Structure containing all loaded cask data
struct CaskDataResult {
    let allCasks: [CaskId: Cask]
    let allCasksCollection: SearchableCaskCollection
    let installedCasksCollection: SearchableCaskCollection
    let outdatedCasksCollection: SearchableCaskCollection
    let categories: [CategoryViewModel]
    let taps: [TapViewModel]
    let bannerConfig: BannerConfig?
}
