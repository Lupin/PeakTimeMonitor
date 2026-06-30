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
        menu.addItem(NSMenuItem(title: "Afficher", action: #selector(showWindowAction), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Préférences", action: #selector(openPrefsAction), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quitter", action: #selector(quitAction), keyEquivalent: "q"))
        // Target = self (AppDelegate), retained by NSApplicationDelegateAdaptor
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }

        // Start as accessory (no Dock icon) until user opens window
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: - Menu actions

    @objc private func showWindowAction() {
        NSLog("[PeakTime] showWindowAction — windows: %d", NSApp.windows.count)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let w = NSApp.windows.first {
            w.makeKeyAndOrderFront(nil)
        }
        // If no window exists, SwiftUI WindowGroup will create one when app becomes active
    }

    @objc private func openPrefsAction() {
        NSLog("[PeakTime] openPrefsAction called")
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Cherche la fenêtre Settings dans les fenêtres ouvertes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApp.windows {
                if window.title.contains("Settings") || window.title.contains("Settings") || window.className.contains("Settings") {
                    window.makeKeyAndOrderFront(nil)
                    return
                }
            }
            // Fallback: ouvre le panneau Settings standard
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    @objc private func quitAction() {
        NSLog("[PeakTime] quitAction called")
        NSApp.terminate(nil)
    }

    // MARK: - Icon update

    private func updateIcon() {
        statusItem.button?.image = makeFeuIcon(state: currentState())
    }

    private func currentState() -> FeuState {
        let d = UserDefaults(suiteName: "group.peakmonitor")
        let slots = d?.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        let om = d?.integer(forKey: "orangeMinutes") ?? 15
        return PeakTimeSlot.currentState(slots: slots, orangeMinutes: om > 0 ? om : 15)
    }

    private func makeFeuIcon(state: FeuState) -> NSImage {
        let img = NSImage(size: NSSize(width: 18, height: 18))
        img.isTemplate = true
        img.lockFocus()
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.clear(CGRect(x: 0, y: 0, width: 18, height: 18))
        let cx = 9.0, r = 2.5, cy: [CGFloat] = [13, 9, 5]
        let fills = [state == .red, state == .orange, state == .green]
        for i in 0..<3 {
            let rect = CGRect(x: cx - r, y: cy[i] - r, width: r*2, height: r*2)
            (fills[i] ? NSColor.controlTextColor : NSColor.tertiaryLabelColor).setFill()
            ctx?.fillEllipse(in: rect)
        }
        img.unlockFocus()
        return img
    }
}
