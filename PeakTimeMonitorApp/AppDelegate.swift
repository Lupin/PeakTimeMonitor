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
        menu.addItem(withTitle: "Afficher", action: #selector(showWindow), keyEquivalent: "")
        menu.addItem(withTitle: "Préférences", action: #selector(openPrefs), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quitter", action: #selector(quitApp), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }

        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    @objc func showWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    @objc func openPrefs() {
        NSApp.activate(ignoringOtherApps: true)
        if NSApp.responds(to: NSSelectorFromString("showSettingsWindow:")) {
            NSApp.perform(NSSelectorFromString("showSettingsWindow:"))
        }
    }

    @objc func quitApp() { NSApp.terminate(nil) }

    func updateIcon() {
        statusItem.button?.image = makeFeuIcon(state: currentState())
    }

    func currentState() -> FeuState {
        let d = UserDefaults(suiteName: "group.peakmonitor")
        let slots = d?.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        let om = d?.integer(forKey: "orangeMinutes") ?? 15
        return PeakTimeSlot.currentState(slots: slots, orangeMinutes: om > 0 ? om : 15)
    }

    func makeFeuIcon(state: FeuState) -> NSImage {
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
