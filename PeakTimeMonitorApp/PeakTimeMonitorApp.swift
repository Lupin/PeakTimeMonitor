import SwiftUI

/// Point d'entrée de l'application PeakTimeMonitor.
/// 
/// L'application n'expose qu'une fenêtre Settings (Préférences) via la scène SwiftUI.
/// La fenêtre principale est gérée manuellement dans ``AppDelegate`` à la place d'un
/// `WindowGroup` pour avoir un contrôle fin sur le cycle de vie AppKit.
@main
struct PeakTimeMonitorApp: App {
    /// Bridge AppKit → SwiftUI : délègue le cycle de vie NSApplication à AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 620, height: 420)
    }
}
