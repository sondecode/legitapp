//
//  SetupView.swift
//  LegitApp
//
//  Created by Milán Várady on 2023. 01. 03..
//

import SwiftUI
import AppKit

/// This view is shown when first launching the app. It welcomes the user and installs dependencies (Homebrew, Xcode Command Line Tools).
struct SetupView: View {
    enum SetupPage {
        case language
        case welcome
        case appliteBrewInfo
        case appliteBrewInstall
        case brewPathDetected
        case brewPathSelection
        case allSet
    }
    
    @AppStorage(Preferences.appLanguageSelected.rawValue) var appLanguageSelected = false

    @State var page: SetupPage = UserDefaults.standard.bool(forKey: Preferences.appLanguageSelected.rawValue) ? .welcome : .language

    @State var detectedBrewInstallation: BrewPaths.PathOption? = nil

    @State var isBrewPathValid = false
    @State var isBrewInstallDone = false

    var body: some View {
        VStack {
            switch page {
            case .language:
                LanguageSelection(page: $page)
                    .transition(.push(from: .trailing))

            case .welcome:
                Welcome()
                    .transition(.push(from: .trailing))

                Spacer()

                pageControlButtons(
                    nextPage: detectedBrewInstallation == nil ? .appliteBrewInfo : .brewPathDetected
                )

            case .appliteBrewInfo:
                LegitAppBrewInfoView(page: $page)
                    .transition(.push(from: .trailing))

                pageControlButtons(
                    nextPage: .appliteBrewInstall,
                    additionalLinks: [PageLink(title: "I already have brew installed", page: .brewPathSelection)]
                )

            case .appliteBrewInstall:
                LegitAppBrewInstall(isDone: $isBrewInstallDone)
                    .transition(.push(from: .trailing))

                Spacer()

                pageControlButtons(
                    nextPage: .allSet,
                    canContinue: isBrewInstallDone
                )

            case .brewPathDetected:
                BrewPathDetectedView(page: $page)
                    .transition(.push(from: .trailing))

                pageControlButtons(
                    nextPage: .allSet,
                    additionalLinks: [
                        PageLink(title: "Use different brew path", page: .brewPathSelection),
                        PageLink(title: "Install separate brew for LegitApp", page: .appliteBrewInstall)
                    ]
                )

            case .brewPathSelection:
                BrewPathSelection(isBrewPathValid: $isBrewPathValid)
                    .transition(.push(from: .trailing))

                pageControlButtons(nextPage: .allSet, canContinue: isBrewPathValid)

            case .allSet:
                AllSet()
                    .transition(.push(from: .trailing))
            }
        }
        .task {
            detectedBrewInstallation = await DependencyManager.detectHomebrew(setPathOption: true)
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
            .frame(width: 600, height: 400)
    }
}
