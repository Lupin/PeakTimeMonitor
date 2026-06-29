import SwiftUI

// Types defined in sibling files within the same target:
// PeakTimeSlot, FeuState, FeuTricoloreView, SettingsView

/// Point d'entrée principal de l'application PeakTimeMonitor.
/// Affiche une fenêtre unique avec le feu tricolore et un timer de rafraîchissement.
@main
struct PeakTimeMonitorApp: App {
    @AppStorage("peakTimeMonitor.group", store: UserDefaults(suiteName: "group.peakmonitor"))
    private var appGroupDefaults: Data = Data()

    var body: some Scene {
        WindowGroup {
            FeuTricoloreView()
                .frame(minWidth: 130, maxWidth: 140,
                       minHeight: 140, maxHeight: 155)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 140, height: 190)
        .windowStyle(.titleBar)

        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 360)
    }
}
