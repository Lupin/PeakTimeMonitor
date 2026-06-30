import Cocoa

/// Objet target pour le NSMenu — séparé de l'AppDelegate pour garantir
/// qu'il est dans la responder chain. Stocké en static pour ne jamais être libéré.
final class MenuTarget: NSObject {
    static let shared = MenuTarget()

    @objc func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Utilise l'API SwiftUI openWindow pour ouvrir la fenêtre "main"
        if NSApp.responds(to: Selector(("openWindow:withIdentifier:"))) {
            NSApp.perform(Selector(("openWindow:withIdentifier:")), with: "main")
        }
    }

    @objc func openPreferences() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Ouvre via le menu application standard
        if let appMenu = NSApp.mainMenu?.items.first?.submenu {
            for item in appMenu.items {
                if item.action == Selector(("showSettingsWindow:")) || item.keyEquivalent == "," {
                    NSApp.sendAction(item.action!, to: item.target, from: item)
                    return
                }
            }
        }
        // Fallback
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let menuTarget = MenuTarget.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()

        let menu = NSMenu()
        let t = menuTarget

        let showItem = NSMenuItem(title: "Afficher", action: #selector(MenuTarget.showMainWindow), keyEquivalent: "")
        showItem.target = t
        menu.addItem(showItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Préférences", action: #selector(MenuTarget.openPreferences), keyEquivalent: ",")
        prefsItem.target = t
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quitter", action: #selector(MenuTarget.quitApp), keyEquivalent: "q")
        quitItem.target = t
        menu.addItem(quitItem)

        // Empêcher l'auto-terminaison du menu
        menu.autoenablesItems = false
        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

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
