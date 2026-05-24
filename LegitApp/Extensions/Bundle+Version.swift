//
//  BundleAppNameExtension.swift
//  LegitApp
//
//  Created by Milán Várady on 2023. 06. 17..
//

import Foundation

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var version: String {
        return appVersion
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
}
