import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = makeFeuIcon(state: currentState())
            button.image?.isTemplate = true
        }

        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Afficher la fenêtre", action: nil, keyEquivalent: "")
        showItem.target = self
        showItem.action = #selector(showWindow)
        menu.addItem(showItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Préférences", action: nil, keyEquivalent: ",")
        prefsItem.target = self
        prefsItem.action = #selector(openPrefs)
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quitter", action: nil, keyEquivalent: "q")
        quitItem.target = self
        quitItem.action = #selector(quitApp)
        menu.addItem(quitItem)

        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }

        // Empêcher l'app de quitter quand la fenêtre est fermée
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Rester actif dans la barre de menu
    }

    @objc private func showWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.isVisible || $0.title.contains("Peak") }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Si la fenêtre n'existe pas encore, on la recrée via le WindowGroup
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func openPrefs() {
        NSApp.activate(ignoringOtherApps: true)
        // Ouvre les Settings via la commande standard
        if #available(macOS 14.0, *) {
            // macOS 14+ : Settings
            let sel = NSSelectorFromString("showSettingsWindow:")
            if NSApp.responds(to: sel) {
                NSApp.perform(sel)
            }
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func updateIcon() {
        statusItem.button?.image = makeFeuIcon(state: currentState())
    }

    private func currentState() -> FeuState {
        let defaults = UserDefaults(suiteName: "group.peakmonitor")
        let slots = defaults?.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        let orangeMin = defaults?.integer(forKey: "orangeMinutes") ?? 15
        return PeakTimeSlot.currentState(slots: slots, orangeMinutes: orangeMin > 0 ? orangeMin : 15)
    }

    private func makeFeuIcon(state: FeuState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.isTemplate = true
        image.lockFocus()
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.clear(CGRect(origin: .zero, size: size))
        let cx: CGFloat = 9, r: CGFloat = 2.5
        let cy: [CGFloat] = [13, 9, 5]
        let fills: [Bool] = [state == .red, state == .orange, state == .green]
        for i in 0..<3 {
            let rect = CGRect(x: cx - r, y: cy[i] - r, width: r * 2, height: r * 2)
            (fills[i] ? NSColor.controlTextColor : NSColor.tertiaryLabelColor).setFill()
            ctx?.fillEllipse(in: rect)
        }
        image.unlockFocus()
        return image
    }
}
