//
//  SetupView+LanguageSelection.swift
//  LegitApp
//

import SwiftUI

extension SetupView {
    struct LanguageSelection: View {
        @Binding var page: SetupPage
        @State private var selectedLanguage: AppLanguage = .selected
        @State private var showRestartAlert = false

        var body: some View {
            VStack(spacing: 18) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 6)

                VStack(spacing: 8) {
                    Text("Choose Display Language", comment: "First launch language selection title")
                        .font(.legitSmallTitle)

                    Text(
                        "Vietnamese is selected by default. You can change this later in Settings.",
                        comment: "First launch language selection description"
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 420)
                }

                Picker("Language", selection: $selectedLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 360)

                Spacer()

                Divider()

                HStack {
                    Spacer()

                    Button("Continue") {
                        let previousLanguage = AppLanguage.selected
                        AppLanguage.apply(selectedLanguage)

                        if selectedLanguage == previousLanguage {
                            withAnimation {
                                page = .welcome
                            }
                        } else {
                            showRestartAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.trailing)
                .padding(.bottom, 8)
            }
            .padding(.top, 32)
            .alert("Restart Required", isPresented: $showRestartAlert) {
                Button("Restart Now") {
                    AppLanguage.relaunch()
                }
            } message: {
                Text("Please restart the app to apply the language change.")
            }
        }
    }
}
