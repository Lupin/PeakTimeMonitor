import Cocoa

/// AppDelegate minimal — Xcode en a besoin pour les projets AppKit/SwiftUI hybrides.
/// L'entry point SwiftUI (@main dans PeakTimeMonitorApp.swift) gère le reste.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Rien de spécial — SwiftUI prend le relais
    }
}
