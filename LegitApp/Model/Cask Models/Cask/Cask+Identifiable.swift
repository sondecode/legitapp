//
//  Cask+Identifiable.swift
//  LegitApp
//
//  Created by Milán Várady on 2025.01.11.
//

import Foundation

extension Cask: Identifiable {
    nonisolated var id: String {
        self.info.fullToken
    }
}
