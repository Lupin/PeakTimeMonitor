import SwiftUI

@main
struct PeakTimeMonitorApp: App {
    @State private var showSettings = false

    var body: some Scene {
        // Fenêtre principale
        WindowGroup {
            FeuTricoloreView()
                .frame(minWidth: 135, maxWidth: 150, minHeight: 175, maxHeight: 210)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 140, height: 190)
        .windowStyle(.titleBar)
        .commands {
            // Raccourci pour les préférences
            CommandGroup(after: .appSettings) {
                Button("Préférences") { showSettings = true }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }

        // Icône dans la barre de menu (toujours visible)
        MenuBarExtra {
            Button("Afficher la fenêtre") {
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Préférences") { showSettings = true }
                .keyboardShortcut(",", modifiers: .command)
            Divider()
            Button("Quitter") { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: "circle.fill")
                .foregroundColor(currentMenuIconColor)
        }
        .menuBarExtraStyle(.menu)

        // Préférences (Cmd+,)
        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 360)
    }

    /// Lit l'état courant pour colorer l'icône de la barre de menu
    private var currentMenuIconColor: Color {
        let defaults = UserDefaults(suiteName: "group.peakmonitor")
        let slots = defaults?.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        let orangeMin = defaults?.integer(forKey: "orangeMinutes") ?? 15
        switch PeakTimeSlot.currentState(slots: slots, orangeMinutes: orangeMin > 0 ? orangeMin : 15) {
        case .red:    return .red
        case .orange: return .orange
        case .green:  return .green
        }
    }
}
