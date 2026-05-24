//
//  Commands.swift
//  LegitApp
//
//  Created by Milán Várady on 2022. 10. 11..
//

import SwiftUI
import Sparkle

struct CommandsMenu: Commands {
    let updaterController: SPUStandardUpdaterController
    
    @Environment(\.openWindow) var openWindow
    
    var body: some Commands {
        SidebarCommands()
        
        CommandGroup(before: .systemServices) {
            Button("Uninstall LegitApp...") {
                openWindow(id: "uninstall-self")
            }
            
            CheckForUpdatesView(updater: updaterController.updater) {
                Text("Check for Updates...", comment: "Check for update menu bar item")
            }
            
            Divider()
        }
        
        CommandGroup(replacing: .newItem) {}
        
        
        CommandGroup(replacing: .help) {
            Link("Website", destination: URL(string: "https://sondecode.github.io/legitapp")!)
            Link("GitHub", destination: URL(string: "https://github.com/sondecode/legitapp")!)
        }
    }
}
