//
//  CategoryViewModel+LocalizedName.swift
//  LegitApp
//
//  Created by Milán Várady on 2025.05.09.
//

import SwiftUI

extension CategoryViewModel {
    var localizedName: LocalizedStringKey {
        LocalizedStringKey(self.name)
    }
}
