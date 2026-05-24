//
//  AppMigrationView.swift
//  LegitApp
//
//  Created by Milán Várady on 2024.12.30.
//

import SwiftUI

struct AppMigrationView: View {
    let width: CGFloat = 620
    let cardPadding: CGFloat = 24

    var body: some View {
        ScrollView {
            VStack {
                description
                    .padding(.vertical, 24)
                
                HStack(spacing: 40) {
                    Card(padding: cardPadding) {
                        ExportView()
                    }
                    
                    Card(padding: cardPadding) {
                        ImportView()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("App Migration")
            .frame(maxWidth: width)
            .padding()
        }
    }

    var description: some View {
        VStack(alignment: .leading) {
            Text(
                "Export all of your currently installed apps to a file. Import the file to another device to install them all. Useful when setting up a new Mac.",
                comment: "App migration view description"
            )
        }
    }
}

#Preview {
    AppMigrationView()
        .padding()
}
