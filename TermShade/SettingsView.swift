//
//  SettingsView.swift
//  TermShade
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller = SettingsController()

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "TermShade"
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Start on login", isOn: Binding(
                get: { controller.launchAtLogin },
                set: { newValue in
                    controller.updateLaunchAtLogin(newValue)
                }
            ))

            if !controller.statusMessage.isEmpty {
                Text(controller.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

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
            controller.refreshLaunchAtLoginState()
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
    }
}

