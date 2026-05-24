//
//  Category.swift
//  LegitApp
//
//  Created by Milán Várady on 2022. 10. 31..
//

import Foundation

typealias CategoryId = String

/// App category object
struct Category: Decodable, Identifiable {
    /// Category id
    let id: String
    /// List of cask ids
    let casks: [CaskId]
    /// SF Symbol of the category
    let sfSymbol: String
    /// Optional category-specific metadata for Homebrew casks
    let apps: [CategoryAppMetadata]
    /// Apps that are listed for discovery but installed from the app website
    let websiteOnlyApps: [WebsiteOnlyApp]

    enum CodingKeys: String, CodingKey {
        case id
        case casks
        case sfSymbol
        case apps
        case websiteOnlyApps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.casks = try container.decode([CaskId].self, forKey: .casks)
        self.sfSymbol = try container.decode(String.self, forKey: .sfSymbol)
        self.apps = try container.decodeIfPresent([CategoryAppMetadata].self, forKey: .apps) ?? []
        self.websiteOnlyApps = try container.decodeIfPresent([WebsiteOnlyApp].self, forKey: .websiteOnlyApps) ?? []
    }
}

struct CategoryAppMetadata: Decodable {
    let id: CaskId
    let viDescription: String
}

struct WebsiteOnlyApp: Decodable {
    let id: CaskId
    let name: String
    let viDescription: String
    let homepage: URL
}

/// Banner advertisement configuration loaded from categories.json
struct BannerConfig: Decodable {
    /// Whether the menu bar banner is enabled
    let enabled: Bool
    /// Whether the sidebar banner (replacing logo) is enabled
    let sidebarBanner: Bool
    /// URL string of the banner image
    let imageUrl: String
    /// URL string to open when the banner is tapped
    let linkUrl: String
    /// Optional fixed display height for the banner image
    let fixedHeight: Double?

    enum CodingKeys: String, CodingKey {
        case enabled
        case sidebarBanner = "sidebar_banner"
        case imageUrl
        case linkUrl
        case fixedHeight
    }
}

/// Top-level wrapper for categories.json
struct CatalogData: Decodable {
    let banner: BannerConfig?
    let categories: [Category]
}
