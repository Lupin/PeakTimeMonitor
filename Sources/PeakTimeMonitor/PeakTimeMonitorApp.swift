import SwiftUI
import PeakTimeMonitorLib

/// Point d'entrée principal de l'application PeakTimeMonitor.
/// Affiche une fenêtre unique avec le feu tricolore et un timer de rafraîchissement.
@main
struct PeakTimeMonitorApp: App {
    @AppStorage("peakTimeMonitor.group", store: UserDefaults(suiteName: "group.peakmonitor"))
    private var appGroupDefaults: Data = Data()

    var body: some Scene {
        WindowGroup {
            FeuTricoloreView()
                .frame(minWidth: 280, idealWidth: 300, maxWidth: 400,
                       minHeight: 360, idealHeight: 400, maxHeight: 500)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 300, height: 400)
        .windowStyle(.titleBar)

        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 360)
    }
}
