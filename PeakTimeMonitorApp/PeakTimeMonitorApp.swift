import SwiftUI
import AppKit

// MARK: - Mini-feu dessiné en monochrome (template)

struct FeuIconView: NSViewRepresentable {
    let state: FeuState

    func makeNSView(context: Context) -> NSImageView {
        let iv = NSImageView()
        iv.imageScaling = .scaleProportionallyDown
        return iv
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = makeFeuIcon(state: state)
    }

    private func makeFeuIcon(state: FeuState) -> NSImage {
        let img = NSImage(size: NSSize(width: 16, height: 16))
        img.isTemplate = true
        img.lockFocus()
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.clear(CGRect(x: 0, y: 0, width: 16, height: 16))
        let cx = 8.0, r = 2.5, cy: [CGFloat] = [11.5, 8, 4.5]
        let fills = [state == .red, state == .orange, state == .green]
        for i in 0..<3 {
            let rect = CGRect(x: cx - r, y: cy[i] - r, width: r*2, height: r*2)
            if fills[i] {
                NSColor.controlAccentColor.setFill()
                ctx?.fillEllipse(in: rect)
            }
            // cercles inactifs : contour discret
            ctx?.setStrokeColor(NSColor.tertiaryLabelColor.cgColor)
            ctx?.setLineWidth(0.8)
            ctx?.strokeEllipse(in: rect)
        }
        img.unlockFocus()
        return img
    }
}

/// Lit l'état courant
private func currentFeuState() -> FeuState {
    let d = UserDefaults(suiteName: "group.peakmonitor")
    let slots = d?.peakTimeSlots ?? PeakTimeSlot.defaultSlots
    let om = d?.integer(forKey: "orangeMinutes") ?? 15
    return PeakTimeSlot.currentState(slots: slots, orangeMinutes: om > 0 ? om : 15)
}

// MARK: - App

@main
struct PeakTimeMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            FeuTricoloreView()
                .frame(minWidth: 135, maxWidth: 150, minHeight: 175, maxHeight: 210)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 140, height: 190)
        .windowStyle(.titleBar)

        MenuBarExtraScene()

        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 340)
    }
}

/// Vue séparée pour le MenuBarExtra avec son propre timer
struct MenuBarExtraScene: Scene {
    @State private var state: FeuState = currentFeuState()
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some Scene {
        MenuBarExtra {
            StateRefreshView(state: $state)
            Button("Afficher") {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                if let w = NSApp.windows.first(where: { $0.title.isEmpty || $0.title == "PeakTimeMonitor" }) {
                    w.makeKeyAndOrderFront(nil)
                }
            }
            Divider()
            SettingsLink { Text("Préférences") }
            Divider()
            Button("Quitter") { NSApp.terminate(nil) }
        } label: {
            FeuIconView(state: state)
                .frame(width: 16, height: 16)
        }
        .menuBarExtraStyle(.menu)
    }
}

/// Vue invisible qui rafraîchit l'état via timer
struct StateRefreshView: View {
    @Binding var state: FeuState
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        EmptyView()
            .onReceive(timer) { _ in
                state = currentFeuState()
            }
    }
}
