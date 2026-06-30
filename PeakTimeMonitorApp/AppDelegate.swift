import Cocoa

/// Handler intermédiaire qui reçoit les actions du menu et les redirige
private class MenuHandler: NSObject {
    var onShow: (() -> Void)?
    var onPrefs: (() -> Void)?
    var onQuit: (() -> Void)?

    @objc func show() { onShow?() }
    @objc func prefs() { onPrefs?() }
    @objc func quit() { onQuit?() }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let menuHandler = MenuHandler()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configurer les actions via closures
        menuHandler.onShow = { [weak self] in self?.showWindow() }
        menuHandler.onPrefs = { [weak self] in self?.openPrefs() }
        menuHandler.onQuit = { NSApp.terminate(nil) }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = makeFeuIcon(state: currentState())
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Afficher", action: #selector(MenuHandler.show), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Préférences", action: #selector(MenuHandler.prefs), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quitter", action: #selector(MenuHandler.quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = menuHandler }
        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }

        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func showWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    private func openPrefs() {
        NSApp.activate(ignoringOtherApps: true)
        if NSApp.responds(to: NSSelectorFromString("showSettingsWindow:")) {
            NSApp.perform(NSSelectorFromString("showSettingsWindow:"))
        }
    }

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
