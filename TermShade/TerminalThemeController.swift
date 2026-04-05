//
//  TerminalThemeController.swift
//  TermShade
//

import SwiftUI
import Foundation
import Combine
import Darwin

private let terminalDomain = "com.apple.Terminal"
private let terminalWindowSettingsKey = "Window Settings"
private let terminalDefaultWindowSettingsKey = "Default Window Settings"
private let terminalStartupWindowSettingsKey = "Startup Window Settings"

@MainActor
final class TerminalThemeController: ObservableObject {
    @Published var availableThemes: [String] = []
    @Published var statusMessage = ""
    @Published private(set) var preferencesRevision = 0

    @AppStorage("lightTheme") var lightTheme = ""
    @AppStorage("darkTheme") var darkTheme = ""

    private let watcherQueue = DispatchQueue(label: "TermShade.TerminalPlistWatcher")
    private let watcherDebounceInterval: TimeInterval = 0.2
    private var plistWatcher: DispatchSourceFileSystemObject?
    private var plistFileDescriptor: CInt = -1
    private var pendingWatcherRefreshWorkItem: DispatchWorkItem?
    private var appearanceObserver: NSObjectProtocol?

    private var terminalPreferencesURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/com.apple.Terminal.plist")
    }

    private var isSandboxed: Bool {
        ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }

    init() {
        refreshThemes()
        startWatchingPlist()
        startWatchingSystemAppearance()
        applyThemeForCurrentSystemAppearance()
    }

    deinit {
        plistWatcher?.cancel()
        plistWatcher = nil
        pendingWatcherRefreshWorkItem?.cancel()
        pendingWatcherRefreshWorkItem = nil

        if let appearanceObserver {
            DistributedNotificationCenter.default().removeObserver(appearanceObserver)
            self.appearanceObserver = nil
        }
    }

    func refreshThemes() {
        do {
            availableThemes = try fetchThemeNamesFromTerminalPreferences()

            // If the current theme is unavailable or not set, default to the first available
            if lightTheme.isEmpty || !availableThemes.contains(lightTheme) {
                lightTheme = availableThemes.first ?? ""
            }

            if darkTheme.isEmpty || !availableThemes.contains(darkTheme) {
                darkTheme = availableThemes.first ?? ""
            }

            if availableThemes.isEmpty {
                statusMessage = "No Terminal themes found in preferences."
            }
        } catch {
            statusMessage = "Failed to load Terminal themes: \(error.localizedDescription)"
        }
    }

    func isUnavailableSelection(_ value: String) -> Bool {
        !value.isEmpty && !availableThemes.contains(value)
    }

    func applyTheme(for colorScheme: ColorScheme) {
        let selectedTheme = colorScheme == .dark ? darkTheme : lightTheme

        guard !selectedTheme.isEmpty else {
            statusMessage = colorScheme == .dark
                ? "Set a dark mode theme to auto-switch in dark mode."
                : "Set a light mode theme to auto-switch in light mode."
            return
        }

        do {
            try applyTerminalTheme(named: selectedTheme)
            setThemeForAllOpenTerminalTabs(theme: selectedTheme)
            statusMessage = ""
        } catch {
            statusMessage = "Could not apply theme '\(selectedTheme)': \(error.localizedDescription)"
        }
    }

    func applyThemeForCurrentSystemAppearance() {
        applyTheme(for: currentSystemColorScheme())
    }

    private func isTerminalAppRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.Terminal" }
    }

    func setThemeForAllOpenTerminalTabs(theme: String) {
        if !isTerminalAppRunning() {
            return
        }
        let script = """
        tell application \"Terminal\"
            repeat with w in windows
                repeat with t in tabs of w
                    set current settings of t to settings set \"\(theme)\"
                end repeat
            end repeat
        end tell
        """
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        process.launch()
    }

    func startWatchingPlist() {
        stopWatchingPlist()

        plistFileDescriptor = open(terminalPreferencesURL.path, O_EVTONLY)
        guard plistFileDescriptor >= 0 else {
            statusMessage = "Could not watch Terminal preferences file."
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: plistFileDescriptor,
            eventMask: [.write, .delete, .rename, .attrib, .extend, .revoke],
            queue: watcherQueue
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let events = source.data

            Task { @MainActor in
                self.scheduleWatcherRefresh()

                if events.contains(.delete) || events.contains(.rename) || events.contains(.revoke) {
                    self.restartPlistWatcher()
                }
            }
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.plistFileDescriptor >= 0 {
                close(self.plistFileDescriptor)
                self.plistFileDescriptor = -1
            }
        }

        plistWatcher = source
        source.resume()
    }

    func stopWatchingPlist() {
        plistWatcher?.cancel()
        plistWatcher = nil
        pendingWatcherRefreshWorkItem?.cancel()
        pendingWatcherRefreshWorkItem = nil
    }

    private func scheduleWatcherRefresh() {
        pendingWatcherRefreshWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.refreshThemes()
            self.preferencesRevision &+= 1
        }

        pendingWatcherRefreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + watcherDebounceInterval, execute: workItem)
    }

    private func restartPlistWatcher() {
        stopWatchingPlist()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.startWatchingPlist()
        }
    }

    private func startWatchingSystemAppearance() {
        stopWatchingSystemAppearance()

        appearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.applyThemeForCurrentSystemAppearance()
            }
        }
    }

    private func stopWatchingSystemAppearance() {
        guard let appearanceObserver else { return }
        DistributedNotificationCenter.default().removeObserver(appearanceObserver)
        self.appearanceObserver = nil
    }

    private func currentSystemColorScheme() -> ColorScheme {
        let globalDefaults = UserDefaults(suiteName: UserDefaults.globalDomain)
        if globalDefaults?.string(forKey: "AppleInterfaceStyle") == "Dark" {
            return .dark
        }

        let match = NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        return match == .darkAqua ? .dark : .light
    }

    private func applyTerminalTheme(named themeName: String) throws {
        guard availableThemes.contains(themeName) else {
            throw NSError(
                domain: "TermShade",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Theme '\(themeName)' was not found in Terminal preferences."]
            )
        }

        var domain = try terminalPreferencesDomain()
        domain[terminalDefaultWindowSettingsKey] = themeName
        domain[terminalStartupWindowSettingsKey] = themeName

        UserDefaults.standard.setPersistentDomain(domain, forName: terminalDomain)
        let synchronized = CFPreferencesAppSynchronize(terminalDomain as CFString)
        if !synchronized {
            throw NSError(
                domain: "TermShade",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Could not save Terminal preferences. If TermShade is sandboxed, disable App Sandbox for this target."]
            )
        }
    }

    private func fetchThemeNamesFromTerminalPreferences() throws -> [String] {
        let domain = try terminalPreferencesDomain()

        guard let windowSettings = domain[terminalWindowSettingsKey] as? [String: Any] else {
            throw NSError(
                domain: "TermShade",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Terminal themes could not be read from preferences."]
            )
        }

        return windowSettings.keys.sorted()
    }

    private func terminalPreferencesDomain() throws -> [String: Any] {
        if let domain = UserDefaults.standard.persistentDomain(forName: terminalDomain), !domain.isEmpty {
            return domain
        }

        if FileManager.default.fileExists(atPath: terminalPreferencesURL.path) {
            let data = try Data(contentsOf: terminalPreferencesURL)
            var format = PropertyListSerialization.PropertyListFormat.binary
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: &format)
            if let dictionary = plist as? [String: Any], !dictionary.isEmpty {
                return dictionary
            }
        }

        let message: String
        if isSandboxed {
            message = "Terminal preferences were not found. TermShade appears sandboxed and may not read com.apple.Terminal. Disable App Sandbox for this target."
        } else {
            message = "Terminal preferences were not found at ~/Library/Preferences/com.apple.Terminal.plist. Open Terminal at least once, then refresh."
        }

        throw NSError(
            domain: "TermShade",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

