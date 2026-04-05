//
//  SettingsController.swift
//  TermShade
//

import Foundation
import ServiceManagement
import Combine
import AppKit

@MainActor
final class SettingsController: ObservableObject {
    @Published var launchAtLogin = false
    @Published var statusMessage = ""

    func refreshLaunchAtLoginState() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLogin = true
            statusMessage = ""
        case .notRegistered, .notFound:
            launchAtLogin = false
            statusMessage = ""
        case .requiresApproval:
            launchAtLogin = true
            statusMessage = "Login item requires approval in System Settings > General > Login Items."
        @unknown default:
            launchAtLogin = false
            statusMessage = "Could not determine login item status."
        }
    }

    func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshLaunchAtLoginState()
        } catch {
            launchAtLogin = !enabled
            statusMessage = "Could not update start on login: \(error.localizedDescription)"
        }
    }
}

