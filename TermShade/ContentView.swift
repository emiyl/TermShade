//
//  ContentView.swift
//  TermShade
//

import SwiftUI

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var controller: TerminalThemeController

    var body: some View {
        VStack {
            Button("TermShade") {
                openWindow(id: "about")
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
            }
            
            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
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

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "TermShade"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appName)
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version \(appVersion) (\(appBuild))")
                .foregroundStyle(.secondary)

            Divider()

            Text("Automatically switches Apple Terminal themes between light and dark mode.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Link("github.com/emiyl/TermShade", destination: URL(string: "https://github.com/emiyl/TermShade")!)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
    }
}

#Preview {
    ContentView()
}
