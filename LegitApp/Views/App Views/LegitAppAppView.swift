//
//  LegitAppAppView.swift
//  LegitApp
//
//  Created by Milán Várady on 2023. 07. 29..
//

import SwiftUI
import Sparkle

/// This view is included in the installed section so users can update and uninstall LegitApp itself
struct LegitAppAppView: View {
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        HStack {
            Image("LegitAppIcon")
                .resizable()
                .frame(width: 54, height: 54)
                .padding(.leading, 5)
            
            // Name and description
            VStack(alignment: .leading) {
                Text("LegitApp", comment: "LegitApp app card title")
                    .font(.system(size: 16, weight: .bold))
                
                Text("This app", comment: "LegitApp app card description")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
                
            CheckForUpdatesView(updater: SPUStandardUpdaterController.shared.updater) {
                Label("Update", systemImage: "arrow.uturn.down")
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Capsule())
            
            Button {
                openWindow(id: "uninstall-self")
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
        .frame(width: AppView.dimensions.width, height: AppView.dimensions.height)
    }
}

struct LegitAppAppView_Previews: PreviewProvider {
    static var previews: some View {
        LegitAppAppView()
    }
}
