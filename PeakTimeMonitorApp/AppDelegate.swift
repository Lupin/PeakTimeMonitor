import Cocoa
import SwiftUI

/// Singleton cible des actions du `NSMenu` de la barre de statut.
///
/// Les `NSMenuItem` AppKit nécessitent un objet target ObjC pour recevoir
/// les actions. Ce singleton n'est jamais libéré et reste accessible depuis
/// le menu pendant toute la durée de vie de l'application.
final class MenuTarget: NSObject, @unchecked Sendable {
    static let shared = MenuTarget()

    /// Affiche ou crée la fenêtre principale du feu tricolore
    @objc func showMainWindow() {
        AppDelegate.instance?.openMainWindow()
    }

    /// Ouvre la fenêtre des préférences (Settings SwiftUI)
    @objc func openPreferences() {
        AppDelegate.instance?.openPreferences()
    }

    /// Quitte l'application
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

/// Délégué AppKit de l'application.
///
/// Gère le cycle de vie NSApplication, la barre de statut macOS avec icône de feu
/// tricolore, la fenêtre principale (créée manuellement plutôt que via `WindowGroup`),
/// et l'ouverture des préférences. L'icône de la barre de statut est rafraîchie
/// toutes les 30 secondes.
final class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    /// Référence faible au singleton pour accès depuis MenuTarget
    nonisolated(unsafe) static weak var instance: AppDelegate?

    /// Élément de la barre de statut macOS contenant l'icône et le menu
    private var statusItem: NSStatusItem!
    /// Timer 30s pour rafraîchir l'icône de la barre de statut
    private var timer: Timer?
    /// Target partagé pour les actions du menu de la barre de statut
    private let menuTarget = MenuTarget.shared

    /// Fenêtre principale créée manuellement — pas gérée par SwiftUI, donc
    /// `isReleasedWhenClosed = false` pour éviter qu'elle soit désallouée à la fermeture
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.instance = self
        NSApp.setActivationPolicy(.regular)

        // Créer la fenêtre manuellement
        createMainWindow()

        // Afficher la fenêtre au lancement
        openMainWindow()

        // Barre de menu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()

        let menu = NSMenu()
        let t = menuTarget

        let showItem = NSMenuItem(title: String(localized: "Show"), action: #selector(MenuTarget.showMainWindow), keyEquivalent: "")
        showItem.target = t; menu.addItem(showItem)
        menu.addItem(.separator())
        let prefsItem = NSMenuItem(title: String(localized: "Preferences"), action: #selector(MenuTarget.openPreferences), keyEquivalent: ",")
        prefsItem.target = t; menu.addItem(prefsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: String(localized: "Quit"), action: #selector(MenuTarget.quitApp), keyEquivalent: "q")
        quitItem.target = t; menu.addItem(quitItem)

        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }

    /// Empêche l'app de quitter quand la dernière fenêtre est fermée — l'utilisateur
    /// doit explicitement choisir Quitter dans le menu
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: - Fenêtre principale (AppKit, pas SwiftUI)

    /// Crée une `NSWindow` hébergeant `FeuTricoloreView` via `NSHostingView`.
    /// La fenêtre est persistante (`isReleasedWhenClosed = false`) pour survivre
    /// aux fermetures multiples.
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
        mainWindow?.title = String(localized: "PeakTimeMonitor")
        mainWindow?.isReleasedWhenClosed = false
        mainWindow?.contentView = hostingView
        mainWindow?.center()
    }

    /// Affiche la fenêtre principale, en la recréant si elle a été libérée.
    /// Passe l'activation policy en `.regular` pour que l'app apparaisse dans le dock.
    func openMainWindow() {
        NSApp.setActivationPolicy(.regular)
        if mainWindow == nil { createMainWindow() }
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Ouvre les préférences en envoyant l'action `showSettingsWindow:` via le menu
    /// AppKit. Si le sélecteur n'est pas trouvé (ex: exécution hors bundle), crée
    /// une fenêtre settings manuelle comme fallback.
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

    /// Fenêtre settings de fallback, créée manuellement si l'action menu standard
    /// n'est pas disponible (ex: exécution en dehors du bundle .app)
    private var settingsWindow: NSWindow?
    private func openSettingsFallback() {
        if settingsWindow == nil {
            let hostingView = NSHostingView(rootView: SettingsView())
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 340),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered, defer: false
            )
            settingsWindow?.title = String(localized: "Preferences")
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.contentView = hostingView
            settingsWindow?.center()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Icon

    /// Lit les créneaux et le délai orange depuis UserDefaults, détermine l'état
    /// courant, puis met à jour l'icône de la barre de statut en conséquence.
    func updateIcon() {
        let d = UserDefaults(suiteName: "group.peakmonitor")
        let slots = d?.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        let om = d?.integer(forKey: "orangeMinutes") ?? 15
        let state = PeakTimeSlot.currentState(slots: slots, orangeMinutes: om > 0 ? om : 15)
        statusItem.button?.image = Self.makeFeuIcon(state: state)
    }

    /// Dessine programmatiquement une icône de feu tricolore 16×16.
    ///
    /// Template image (monochrome) : le cercle actif est en `labelColor`,
    /// les inactifs en `tertiaryLabelColor`. La disposition verticale est :
    /// rouge en bas (y=11.5), orange au milieu (y=8), vert en haut (y=4.5).
    /// - Parameter state: L'état du feu déterminant quel cercle est allumé
    /// - Returns: Une `NSImage` template 16×16
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
