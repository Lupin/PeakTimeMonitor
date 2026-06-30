import SwiftUI
import Combine

/// ViewModel principal du feu tricolore.
///
/// Rafraîchit l'état toutes les 30 secondes, au focus de la fenêtre et à chaque
/// modification des préférences (notification distribuée inter-processus). Lit les
/// créneaux depuis le UserDefaults partagé `group.peakmonitor`.
@MainActor
final class FeuViewModel: ObservableObject {
    /// État courant du feu (vert/off-peak, orange/imminent, rouge/actif)
    @Published var state: FeuState = .green
    /// Créneau du prochain peak, formaté "HH:MM–HH:MM" ou "—" si aucun
    @Published var prochainePlage: String = "—"
    /// Compte à rebours avant le prochain peak, ex: "45 min" ou "1h 30m"
    @Published var compteARebours: String = ""

    /// UserDefaults partagé entre l'app principale et l'extension de barre de statut
    private let defaults = UserDefaults(suiteName: "group.peakmonitor")!
    /// Timer 30s — `nonisolated(unsafe)` car accédé depuis le callback non-MainActor
    nonisolated(unsafe) private var timer: Timer?

    init() {
        refresh()
        // Recharger quand les prefs sont modifiées (notification inter-process)
        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("PeakTimeSlotsChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        // Aussi au focus de la fenêtre
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }

    /// Recalcule l'état du feu et le prochain créneau à partir des données UserDefaults.
    /// Appelé périodiquement par le timer, ainsi qu'au focus et sur changement de préférences.
    func refresh() {
        defaults.synchronize()
        let slots = defaults.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        let orangeMin = defaults.orangeMinutes
        state = PeakTimeSlot.currentState(slots: slots, orangeMinutes: orangeMin)
        let now = Date()
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: now)
        let cur = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        // Filtrer les créneaux du jour (aujourd'hui ou tous les jours ouvrables)
        let today = slots.filter { $0.weekday == weekday || ($0.weekday == 0 && weekday >= 2 && weekday <= 6) }.sorted { ($0.startHour*60+$0.startMinute) < ($1.startHour*60+$1.startMinute) }
        var next: PeakTimeSlot?, minD = Int.max
        for s in today { let d = (s.startHour*60+s.startMinute)-cur; if d>0 && d<minD { minD=d; next=s } }
        if let n = next {
            prochainePlage = String(format:"%02d:%02d–%02d:%02d", n.startHour, n.startMinute, n.endHour, n.endMinute)
            compteARebours = minD < 60 ? "\(minD) min" : "\(minD/60)h\(minD%60>0 ? " \(minD%60)m" : "")"
        } else {
            prochainePlage = "—"
            compteARebours = ""
        }
    }
}

/// Un cercle lumineux du feu tricolore.
///
/// Actif : couleur pleine, légèrement agrandi, opaque.
/// Inactif : grisé, réduit, semi-transparent.
struct CercleFeu: View {
    /// Couleur du cercle quand il est actif (red, orange, green)
    let color: Color
    /// Si `true`, le cercle est allumé ; sinon grisé et discret
    let isActive: Bool
    
    var body: some View {
        Circle().fill(isActive ? color : .gray.opacity(0.2))
            .frame(width: 24, height: 24)
            .overlay(Circle().stroke(isActive ? color : .gray.opacity(0.15), lineWidth: 2))
            .scaleEffect(isActive ? 1.1 : 0.9)
            .opacity(isActive ? 1 : 0.4)
            .animation(.easeInOut(duration: 0.5), value: isActive)
    }
}

/// Vue principale du feu tricolore affichant l'état tarifaire (off-peak / peak).
///
/// Composée de trois cercles (rouge, orange, vert), d'une ligne de statut textuel
/// et du prochain créneau avec compte à rebours. La fenêtre est gérée manuellement
/// par ``AppDelegate`` via `NSHostingView`.
public struct FeuTricoloreView: View {
    /// ViewModel pilotant l'état et les rafraîchissements périodiques
    @StateObject private var vm = FeuViewModel()
    public init() {}

    public var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: 4) {
                CercleFeu(color: .red, isActive: vm.state == .red)
                CercleFeu(color: .orange, isActive: vm.state == .orange)
                CercleFeu(color: .green, isActive: vm.state == .green)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.85)).shadow(radius: 3))

            Text(etat).font(.system(size: 12, weight: .semibold)).foregroundColor(couleur)
            Text(tarif).font(.system(size: 9)).foregroundColor(.secondary)

            Spacer().frame(height: 2)

            HStack(spacing: 3) {
                Text(vm.prochainePlage).font(.system(size: 9, design: .monospaced))
                if !vm.compteARebours.isEmpty {
                    Text("·").font(.system(size: 9)).foregroundColor(.secondary)
                    Text(vm.compteARebours).font(.system(size: 9, design: .monospaced)).foregroundColor(.orange)
                }
            }
        }
        .padding(8)
        .frame(minWidth: 135, maxWidth: 150, minHeight: 175, maxHeight: 210)
        .background(Color(.windowBackgroundColor))
        .onAppear { vm.refresh() }
    }

    /// Libellé texte correspondant à l'état actuel (Off-Peak / Peak <15 min / Peak actif)
    private var etat: String { ["green":"Off-Peak","orange":"Peak <15 min","red":"Peak actif"][vm.state.rawValue] ?? "" }
    /// Description du tarif (Tarif normal / Préparation / Tarif ×2)
    private var tarif: String { ["green":"Tarif normal","orange":"Préparation","red":"Tarif ×2"][vm.state.rawValue] ?? "" }
    /// Couleur du texte d'état, synchronisée avec l'état du feu
    private var couleur: Color { [.green:.green,.orange:.orange,.red:.red][vm.state] ?? .primary }
}

#if DEBUG
struct FeuTricoloreView_Previews: PreviewProvider {
    static var previews: some View { FeuTricoloreView() }
}
#endif
