import SwiftUI

@main
struct PeakTimeMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var state: FeuState = .green

    var body: some Scene {
        WindowGroup {
            FeuTricoloreView()
                .frame(minWidth: 135, maxWidth: 150, minHeight: 175, maxHeight: 210)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 140, height: 190)
        .windowStyle(.titleBar)

        MenuBarExtra {
            Button("Afficher") {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                if let w = NSApp.windows.first(where: { $0.title.isEmpty || $0.title == "PeakTimeMonitor" }) {
                    w.makeKeyAndOrderFront(nil)
                }
            }
            Divider()
            SettingsLink { Text("Préférences") }
                .keyboardShortcut(",", modifiers: .command)
            Divider()
            Button("Quitter") { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
        } label: {
            Label("PeakTime", image: "")
                .labelStyle(.iconOnly)
                .overlay(
                    HStack(spacing: 2) {
                        Circle().fill(state == .red    ? Color.red    : Color.gray.opacity(0.35)).frame(width: 6, height: 6)
                        Circle().fill(state == .orange ? Color.orange : Color.gray.opacity(0.35)).frame(width: 6, height: 6)
                        Circle().fill(state == .green  ? Color.green  : Color.gray.opacity(0.35)).frame(width: 6, height: 6)
                    }
                )
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 340)
    }
}
