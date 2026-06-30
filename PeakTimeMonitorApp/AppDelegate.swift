import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Créer l'icône dans la barre de menu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = makeFeuIcon(state: currentState())
            button.image?.isTemplate = true
            button.action = #selector(statusBarClicked)
            button.target = self
        }

        // Menu contextuel
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Afficher la fenêtre", action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Préférences", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quitter", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        // Timer de rafraîchissement de l'icône
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }

    @objc private func statusBarClicked() {
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showWindow() {
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    @objc private func quit() {
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

    /// Dessine un mini-feu tricolore monochrome (3 cercles) dans une image 18×18
    private func makeFeuIcon(state: FeuState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.isTemplate = true

        image.lockFocus()
        let ctx = NSGraphicsContext.current?.cgContext

        // Fond transparent
        ctx?.clear(CGRect(origin: .zero, size: size))

        // Positions des 3 cercles
        let cx: CGFloat = 9
        let cy: [CGFloat] = [13, 9, 5] // rouge en haut, orange milieu, vert en bas
        let r: CGFloat = 2.5

        let isTop:    Bool = state == .red
        let isMiddle: Bool = state == .orange
        let isBottom: Bool = state == .green

        let fills: [Bool] = [isTop, isMiddle, isBottom]

        for i in 0..<3 {
            let rect = CGRect(x: cx - r, y: cy[i] - r, width: r * 2, height: r * 2)
            if fills[i] {
                NSColor.controlTextColor.setFill()
            } else {
                NSColor.tertiaryLabelColor.setFill()
            }
            ctx?.fillEllipse(in: rect)
        }

        image.unlockFocus()
        return image
    }
}
