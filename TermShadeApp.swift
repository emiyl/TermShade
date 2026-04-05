//
//  ContentView.swift
//  TermShade
//

import SwiftUI

@main
struct TermShadeApp: App {
    @StateObject private var controller = TerminalThemeController()

    var body: some Scene {
        MenuBarExtra("TermShade", systemImage: "circle.lefthalf.filled") {
            ContentView()
                .environmentObject(controller)
        }
    }
}
