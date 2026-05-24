//
//  HomeView+SortingOptions.swift
//  LegitApp
//
//  Created by Milán Várady on 2025.01.12.
//

import SwiftUI

extension HomeView {
    struct SearchFieldToolbar: View {
        @Binding var searchText: String
        @Binding var showSearchResults: Bool
        @ObservedObject var caskCollection: SearchableCaskCollection

        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search apps", text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 220)
                    .onSubmit {
                        Task {
                            await caskCollection.search(query: searchText)
                            showSearchResults = !searchText.isEmpty
                        }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        showSearchResults = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onChange(of: searchText) { _, newValue in
                searchText = String(newValue.prefix(30))

                if searchText.isEmpty {
                    showSearchResults = false
                    return
                }

                Task {
                    await caskCollection.search(query: searchText)
                    showSearchResults = true
                }
            }
        }
    }

    struct SortingOptionsToolbar: View {
        // Sorting options
        @AppStorage(Preferences.searchSortOption.rawValue) var sortBy = SortingOptions.mostDownloaded
        @AppStorage(Preferences.hideUnpopularApps.rawValue) var hideUnpopularApps = false
        @AppStorage(Preferences.hideDisabledApps.rawValue) var hideDisabledApps = false

        var body: some View {
            Menu {
                Picker("Sort By", selection: $sortBy) {
                    ForEach(SortingOptions.allCases) { option in
                        Text(option.description)
                            .tag(option)
                    }
                }
                .pickerStyle(.inline)

                Toggle(isOn: $hideUnpopularApps) {
                    Text("Hide apps with few downloads", comment: "Few downloads search filter")
                }

                Toggle(isOn: $hideDisabledApps) {
                    Text("Hide disabled apps", comment: "Disabled apps search filter")
                }
            } label: {
                Label("Search Sorting Options", systemImage: "slider.horizontal.3")
                    .labelStyle(.titleAndIcon)
            }
        }
    }
}
