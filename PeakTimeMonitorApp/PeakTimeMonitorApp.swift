import SwiftUI

// MARK: - App

@main
struct PeakTimeMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("PeakTimeMonitor") {
            FeuTricoloreView()
                .frame(minWidth: 135, maxWidth: 150, minHeight: 175, maxHeight: 210)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 140, height: 190)
        .windowStyle(.titleBar)

        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 340)
    }
}
