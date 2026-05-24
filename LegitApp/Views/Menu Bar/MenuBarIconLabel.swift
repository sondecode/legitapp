//
//  MenuBarIconLabel.swift
//  LegitApp
//

import SwiftUI

/// Status bar icon with optional badge overlay
struct MenuBarIconLabel: View {
    let activeTaskCount: Int
    let updatesCount: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "mug.fill")

            if activeTaskCount > 0 {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: 3, y: -3)
            } else if updatesCount > 0 {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .offset(x: 3, y: -3)
            }
        }
    }
}
