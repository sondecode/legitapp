//
//  CategoryView.swift
//  LegitApp
//
//  Created by Milán Várady on 2022. 11. 02..
//

import SwiftUI

/// Detail view used in the category section
struct CategoryView: View {
    let category: CategoryViewModel

    var body: some View {
        VStack {
            AppGridView(casks: category.casks, appRole: .installAndManage)
                .id(category.id)
        }
        .navigationTitle(category.localizedName)
    }
}

#Preview {
    CategoryView(category:
        .init(
            name: "Test",
            sfSymbol: "star",
            casks: Array(repeating: .dummy, count: 8),
            casksCoupled: [Array(repeating: .dummy, count: 8)]
        )
    )
}
