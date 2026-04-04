//
//  ContentView.swift
//  TermShade
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var controller = TerminalThemeController()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TermShade")
                .font(.largeTitle.bold())

            Text("Pick Terminal themes for light and dark mode.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Light Mode Theme", selection: $controller.lightTheme) {
                Text("Not set").tag("")
                if controller.isUnavailableSelection(controller.lightTheme) {
                    Text("\(controller.lightTheme) (unavailable)").tag(controller.lightTheme)
                }
                ForEach(controller.availableThemes, id: \.self) { theme in
                    Text(theme).tag(theme)
                }
            }

            Picker("Dark Mode Theme", selection: $controller.darkTheme) {
                Text("Not set").tag("")
                if controller.isUnavailableSelection(controller.darkTheme) {
                    Text("\(controller.darkTheme) (unavailable)").tag(controller.darkTheme)
                }
                ForEach(controller.availableThemes, id: \.self) { theme in
                    Text(theme).tag(theme)
                }
            }

            if !controller.statusMessage.isEmpty {
                Text(controller.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .onAppear {
            controller.refreshThemes()
            controller.applyTheme(for: colorScheme)
            controller.startWatchingPlist()
        }
        .onDisappear {
            controller.stopWatchingPlist()
        }
        .onChange(of: colorScheme) { _, newScheme in
            controller.applyTheme(for: newScheme)
        }
        .onChange(of: controller.lightTheme) { _, _ in
            controller.applyTheme(for: colorScheme)
        }
        .onChange(of: controller.darkTheme) { _, _ in
            controller.applyTheme(for: colorScheme)
        }
        .onChange(of: controller.preferencesRevision) { _, _ in
            controller.applyTheme(for: colorScheme)
        }
    }
}