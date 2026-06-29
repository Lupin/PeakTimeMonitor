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
                .frame(minWidth: 160, maxWidth: 200,
                       minHeight: 180, maxHeight: 220)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 180, height: 200)
        .windowStyle(.titleBar)

        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 360)
    }
}
