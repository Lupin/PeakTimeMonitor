import SwiftUI
import Combine

@MainActor
final class FeuViewModel: ObservableObject {
    @Published var state: FeuState = .green
    @Published var prochainePlage: String = "—"
    @Published var compteARebours: String = ""

    private let defaults = UserDefaults(suiteName: "group.peakmonitor")!
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

    /// Appeler pour forcer un rafraîchissement (ex: au focus de la fenêtre)
    func refresh() {
        defaults.synchronize()
        let slots = defaults.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        let orangeMin = defaults.orangeMinutes
        state = PeakTimeSlot.currentState(slots: slots, orangeMinutes: orangeMin)
        let now = Date()
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: now)
        let cur = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
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

struct CercleFeu: View {
    let color: Color; let isActive: Bool
    var body: some View {
        Circle().fill(isActive ? color : .gray.opacity(0.2))
            .frame(width: 24, height: 24)
            .overlay(Circle().stroke(isActive ? color : .gray.opacity(0.15), lineWidth: 2))
            .scaleEffect(isActive ? 1.1 : 0.9)
            .opacity(isActive ? 1 : 0.4)
            .animation(.easeInOut(duration: 0.5), value: isActive)
    }
}

public struct FeuTricoloreView: View {
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

    private var etat: String { ["green":"Off-Peak","orange":"Peak <15 min","red":"Peak actif"][vm.state.rawValue] ?? "" }
    private var tarif: String { ["green":"Tarif normal","orange":"Préparation","red":"Tarif ×2"][vm.state.rawValue] ?? "" }
    private var couleur: Color { [.green:.green,.orange:.orange,.red:.red][vm.state] ?? .primary }
}

#if DEBUG
struct FeuTricoloreView_Previews: PreviewProvider {
    static var previews: some View { FeuTricoloreView() }
}
#endif
