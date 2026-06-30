import SwiftUI

@main
struct PeakTimeMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var state: FeuState = .green

    var body: some Scene {
        // Fenêtre principale
        WindowGroup {
            FeuTricoloreView()
                .frame(minWidth: 135, maxWidth: 150, minHeight: 175, maxHeight: 210)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 140, height: 190)
        .windowStyle(.titleBar)

        // Icône barre de menu : mini-feu tricolore
        MenuBarExtra {
            Button("Afficher") {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            }
            Divider()
            SettingsLink {
                Text("Préférences")
            }
            .keyboardShortcut(",", modifiers: .command)
            Divider()
            Button("Quitter") { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
        } label: {
            HStack(spacing: 2) {
                Circle().frame(width: 7, height: 7)
                    .foregroundColor(state == .red ? .primary : .secondary.opacity(0.25))
                Circle().frame(width: 7, height: 7)
                    .foregroundColor(state == .orange ? .primary : .secondary.opacity(0.25))
                Circle().frame(width: 7, height: 7)
                    .foregroundColor(state == .green ? .primary : .secondary.opacity(0.25))
            }
            .padding(.horizontal, 2)
        }
        .menuBarExtraStyle(.menu)

        // Préférences
        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 340)
    }
}
