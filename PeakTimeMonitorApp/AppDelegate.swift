import Cocoa
import SwiftUI

/// Objet target pour le NSMenu — singleton, jamais libéré
final class MenuTarget: NSObject {
    static let shared = MenuTarget()

    @objc func showMainWindow() {
        AppDelegate.instance?.openMainWindow()
    }

    @objc func openPreferences() {
        AppDelegate.instance?.openPreferences()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var instance: AppDelegate?

    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let menuTarget = MenuTarget.shared

    /// Fenêtre principale créée manuellement (pas via SwiftUI WindowGroup)
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.instance = self
        NSApp.setActivationPolicy(.regular)

        // Créer la fenêtre manuellement
        createMainWindow()

        // Barre de menu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()

        let menu = NSMenu()
        let t = menuTarget

        let showItem = NSMenuItem(title: "Afficher", action: #selector(MenuTarget.showMainWindow), keyEquivalent: "")
        showItem.target = t; menu.addItem(showItem)
        menu.addItem(.separator())
        let prefsItem = NSMenuItem(title: "Préférences", action: #selector(MenuTarget.openPreferences), keyEquivalent: ",")
        prefsItem.target = t; menu.addItem(prefsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quitter", action: #selector(MenuTarget.quitApp), keyEquivalent: "q")
        quitItem.target = t; menu.addItem(quitItem)

        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: - Fenêtre principale (AppKit, pas SwiftUI)

    private func createMainWindow() {
        let contentView = FeuTricoloreView()
            .frame(minWidth: 135, maxWidth: 150, minHeight: 175, maxHeight: 210)

        let hostingView = NSHostingView(rootView: contentView)

        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 140, height: 190),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        mainWindow?.title = "PeakTimeMonitor"
        mainWindow?.isReleasedWhenClosed = false
        mainWindow?.contentView = hostingView
        mainWindow?.center()
    }

    func openMainWindow() {
        NSApp.setActivationPolicy(.regular)
        if mainWindow == nil { createMainWindow() }
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openPreferences() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Ouvre les Settings SwiftUI via NSApp (fonctionne dans Xcode et hors Xcode)
        if let appMenu = NSApp.mainMenu?.item(at: 0)?.submenu {
            for item in appMenu.items {
                let sel = item.action
                if sel == Selector(("showSettingsWindow:")) || sel == Selector(("showPreferencesWindow:")) {
                    NSApp.sendAction(sel!, to: item.target, from: item)
                    return
                }
            }
        }
        // Fallback: créer une fenêtre settings manuelle
        openSettingsFallback()
    }

    private var settingsWindow: NSWindow?
    private func openSettingsFallback() {
        if settingsWindow == nil {
            let hostingView = NSHostingView(rootView: SettingsView())
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 340),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered, defer: false
            )
            settingsWindow?.title = "Préférences"
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.contentView = hostingView
            settingsWindow?.center()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Icon

    func updateIcon() {
        let d = UserDefaults(suiteName: "group.peakmonitor")
        let slots = d?.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        let om = d?.integer(forKey: "orangeMinutes") ?? 15
        let state = PeakTimeSlot.currentState(slots: slots, orangeMinutes: om > 0 ? om : 15)
        statusItem.button?.image = Self.makeFeuIcon(state: state)
    }

    static func makeFeuIcon(state: FeuState) -> NSImage {
        let img = NSImage(size: NSSize(width: 16, height: 16))
        img.isTemplate = true
        img.lockFocus()
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.clear(CGRect(x: 0, y: 0, width: 16, height: 16))
        let cx = 8.0, r = 2.5, cy: [CGFloat] = [11.5, 8, 4.5]
        let fills = [state == .red, state == .orange, state == .green]
        for i in 0..<3 {
            let rect = CGRect(x: cx - r, y: cy[i] - r, width: r*2, height: r*2)
            (fills[i] ? NSColor.labelColor : NSColor.tertiaryLabelColor).setFill()
            ctx?.fillEllipse(in: rect)
        }
        img.unlockFocus()
        return img
    }
}
