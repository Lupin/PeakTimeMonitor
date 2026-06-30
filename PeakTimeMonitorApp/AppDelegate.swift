import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()

        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Afficher", action: #selector(showMainWindow), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Préférences", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quitter", action: #selector(terminate), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: - Actions

    @objc func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if !window.title.contains("Settings"), !window.title.contains("Preferences") {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    @objc func openPreferences() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if NSApp.responds(to: Selector(("showSettingsWindow:"))) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }

    // MARK: - Icon

    func updateIcon() {
        statusItem.button?.image = AppDelegate.makeFeuIcon(state: currentState())
    }

    private func currentState() -> FeuState {
        let d = UserDefaults(suiteName: "group.peakmonitor")
        let slots = d?.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        let om = d?.integer(forKey: "orangeMinutes") ?? 15
        return PeakTimeSlot.currentState(slots: slots, orangeMinutes: om > 0 ? om : 15)
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
