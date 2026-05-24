//
//  ContentView+SidebarViews.swift
//  LegitApp
//
//  Created by Milán Várady on 2024.12.26.
//

import SwiftUI

extension ContentView {
    var sidebarViews: some View {
        VStack(spacing: 0) {
            SidebarBrandHeader(bannerConfig: caskManager.bannerConfig)

            List(selection: $selection) {
                Label("Discover", systemImage: "house.fill")
                    .tag(SidebarItem.home)

                UpdateSidebarItem(caskCollection: caskManager.outdatedCasks)
                    .tag(SidebarItem.updates)

                Label("Installed", systemImage: "externaldrive.fill.badge.checkmark")
                    .tag(SidebarItem.installed)

                Label("Active Tasks", systemImage: "gearshape.arrow.triangle.2.circlepath")
                    .badge(caskManager.activeTasks.count)
                    .tag(SidebarItem.activeTasks)

                Label("App Migration", systemImage: "square.and.arrow.up.on.square")
                    .tag(SidebarItem.appMigration)

                Section("Categories") {
                    ForEach(caskManager.categories) { category in
                        Label(category.localizedName, systemImage: category.sfSymbol)
                            .tag(SidebarItem.appCategory(category: category))
                    }
                }

                if !caskManager.taps.isEmpty {
                    Section("Taps") {
                        ForEach(caskManager.taps) { tap in
                            Label(tap.title, systemImage: "spigot")
                                .tag(SidebarItem.tap(tap: tap))
                                .truncationMode(.head)
                        }
                    }
                }

                Section("Homebrew") {
                    Label("Services", systemImage: "server.rack")
                        .tag(SidebarItem.services)

                    Label("Manage Homebrew", systemImage: "mug")
                        .tag(SidebarItem.brew)
                }
            }
        }
    }

    private struct SidebarBrandHeader: View {
        let bannerConfig: BannerConfig?

        /// Returns true if the app has been installed for at least 3 days
        private var shouldShowSidebarBanner: Bool {
                #if DEBUG
                return true
                #else
                guard let firstLaunch = UserDefaults.standard.object(forKey: Preferences.firstLaunchDate.rawValue) as? Date else {
                    return false
                }
                return Date().timeIntervalSince(firstLaunch) >= 259200 // 3 days in seconds
                #endif
        }

        private var activeBanner: BannerConfig? {
            guard let banner = bannerConfig,
                  banner.enabled,
                  banner.sidebarBanner,
                  shouldShowSidebarBanner else { return nil }
            return banner
        }

        var body: some View {
            if let banner = activeBanner,
               let imageURL = URL(string: banner.imageUrl),
               let linkURL = URL(string: banner.linkUrl) {
                Button {
                    NSWorkspace.shared.open(linkURL)
                } label: {
                    BannerImageView(imageURL: imageURL)
                        .frame(maxWidth: .infinity)
                        .frame(height: CGFloat(banner.fixedHeight ?? 56))
                        .clipped()
                }
                .buttonStyle(.plain)
                .help("Xem thêm tại \(banner.linkUrl)")
                .background(.regularMaterial)
                .padding(.bottom, 8)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        logo

                        VStack(alignment: .leading, spacing: 1) {
                            Text("LegitApp")
                                .font(.headline.weight(.semibold))

                            Text("for Vietnamese", comment: "Sidebar app tagline")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    HStack {
                        Spacer(minLength: 0)
                        logo
                        Spacer(minLength: 0)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(.regularMaterial)
                .padding(.bottom, 8)
            }
        }

        private var logo: some View {
            Image("LegitAppIcon")
                .resizable()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
        }
    }

    // Extract the update item because we need the badge to react to changes of outdatedCasks
    private struct UpdateSidebarItem: View {
        @ObservedObject var caskCollection: SearchableCaskCollection

        var body: some View {
            Label("Updates", systemImage: "arrow.clockwise.circle.fill")
                .badge(caskCollection.casks.count)
        }
    }
}
