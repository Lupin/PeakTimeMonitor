import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = makeFeuIcon(state: currentState())
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(toggleWindow)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }

        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    /// Clic gauche = afficher fenêtre, clic droit = menu contextuel
    @objc private func toggleWindow() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            showMainWindow()
        }
    }

    @objc private func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let showItem = NSMenuItem(title: "Afficher la fenêtre", action: #selector(showMainWindow), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)
        menu.addItem(.separator())
        let prefsItem = NSMenuItem(title: "Préférences", action: #selector(openPrefs), keyEquivalent: ",")
        menu.addItem(prefsItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quitter", action: #selector(quitApp), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openPrefs() {
        NSApp.activate(ignoringOtherApps: true)
        let sel = NSSelectorFromString("showSettingsWindow:")
        if NSApp.responds(to: sel) {
            NSApp.perform(sel)
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
