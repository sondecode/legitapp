//
//  String+PaddedWithQuotes.swift
//  LegitApp
//
//  Created by Milán Várady on 2025.05.09.
//

import Foundation

extension String {
    func paddedWithQuotes() -> String {
        "\"\(self)\""
    }
}
