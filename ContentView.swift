//
//  ContentView.swift
//  TermShade
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var controller = TerminalThemeController()
    @State private var isHoveringQuit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TermShade")
                .font(.headline)

            Text("Pick Terminal themes for light and dark mode.\nWritten by emiyl.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text("Light mode theme")
                Spacer()
                Picker("Light mode Theme", selection: $controller.lightTheme) {
                    if controller.isUnavailableSelection(controller.lightTheme) {
                        Text("\(controller.lightTheme) (unavailable)").tag(controller.lightTheme)
                    }
                    ForEach(controller.availableThemes, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
                .labelsHidden()
            }

            HStack {
                Text("Dark mode theme")
                Spacer()
                Picker("Dark mode theme", selection: $controller.darkTheme) {
                    if controller.isUnavailableSelection(controller.darkTheme) {
                        Text("\(controller.darkTheme) (unavailable)").tag(controller.darkTheme)
                    }
                    ForEach(controller.availableThemes, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
                .labelsHidden()
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
                HStack {
                    Text("Quit TermShade")
                    Spacer()
                    Text("⌘Q")
                        .foregroundColor(.gray)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHoveringQuit ? Color.accentColor : Color.clear)
                        .padding(.vertical, -6)
                        .padding(.horizontal, -8)
                )
            }
            .onHover { hovering in
                isHoveringQuit = hovering
            }
            .keyboardShortcut("q", modifiers: .command)
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(15)
        .onAppear {
            controller.refreshThemes()
            // Default to first available theme if not set
            if controller.lightTheme.isEmpty, let first = controller.availableThemes.first {
                controller.lightTheme = first
            }
            if controller.darkTheme.isEmpty, let first = controller.availableThemes.first {
                controller.darkTheme = first
            }
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
        .padding()
    }
}

#Preview {
    ContentView()
}
