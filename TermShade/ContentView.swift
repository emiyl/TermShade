//
//  ContentView.swift
//  TermShade
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var controller: TerminalThemeController
    @State private var isHoveringQuit = false

    var body: some View {
        VStack {
            Button(action: {}) {
                Text("TermShade")
            }

            Divider()

            Picker("Light mode theme", selection: $controller.lightTheme) {
                if controller.isUnavailableSelection(controller.lightTheme) {
                    Text("\(controller.lightTheme) (unavailable)").tag(controller.lightTheme)
                }
                ForEach(controller.availableThemes, id: \.self) { theme in
                    Text(theme).tag(theme)
                }
            }

            Picker("Dark mode theme", selection: $controller.darkTheme) {
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
            
            Divider()
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
            }
            .keyboardShortcut("q", modifiers: .command)
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .onAppear {
            controller.refreshThemes()
            // Default to first available theme if not set
            if controller.lightTheme.isEmpty, let first = controller.availableThemes.first {
                controller.lightTheme = first
            }
            if controller.darkTheme.isEmpty, let first = controller.availableThemes.first {
                controller.darkTheme = first
            }
            controller.applyThemeForCurrentSystemAppearance()
        }
        .onChange(of: controller.lightTheme) { _, _ in
            controller.applyThemeForCurrentSystemAppearance()
        }
        .onChange(of: controller.darkTheme) { _, _ in
            controller.applyThemeForCurrentSystemAppearance()
        }
        .onChange(of: controller.preferencesRevision) { _, _ in
            controller.applyThemeForCurrentSystemAppearance()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
