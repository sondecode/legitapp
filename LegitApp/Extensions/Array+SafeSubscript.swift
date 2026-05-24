//
//  Array+SafeSubscript.swift
//  LegitApp
//
//  Created by Milán Várady on 2025.05.09.
//

import Foundation

extension Array {
    subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
