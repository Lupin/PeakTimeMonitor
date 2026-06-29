import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class FeuViewModel: ObservableObject {
    @Published var state: FeuState = .green
    @Published var prochainePlage: String = "—"
    @Published var compteARebours: String = ""

    private let defaults = UserDefaults(suiteName: "group.peakmonitor")!
    nonisolated(unsafe) private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        let slots = defaults.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        state = PeakTimeSlot.currentState(slots: slots)

        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute

        let todaySlots = slots.filter { $0.weekday == weekday }
            .sorted { ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute) }

        // Find next upcoming slot
        var nextSlot: PeakTimeSlot?
        var minDiff = Int.max
        for slot in todaySlots {
            let startMinutes = slot.startHour * 60 + slot.startMinute
            let diff = startMinutes - currentMinutes
            if diff > 0 && diff < minDiff {
                minDiff = diff
                nextSlot = slot
            }
        }

        if let next = nextSlot {
            let h = next.startHour
            let m = next.startMinute
            prochainePlage = String(format: "%02d:%02d – %02d:%02d", h, m, next.endHour, next.endMinute)

            if minDiff < 60 {
                compteARebours = "dans \(minDiff) min"
            } else {
                let hours = minDiff / 60
                let mins = minDiff % 60
                compteARebours = "dans \(hours)h\(mins > 0 ? " \(mins)min" : "")"
            }
        } else {
            prochainePlage = "Aucune aujourd'hui"
            compteARebours = ""
        }
    }
}

// MARK: - Cercle composant

struct CercleFeu: View {
    let color: Color
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(isActive ? color : Color.gray.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay(
                Circle()
                    .stroke(isActive ? color : Color.gray.opacity(0.15), lineWidth: 3)
            )
            .scaleEffect(isActive ? 1.1 : 0.85)
            .opacity(isActive ? 1.0 : 0.35)
            .animation(.easeInOut(duration: 0.5), value: isActive)
    }
}

// MARK: - Vue principale

public struct FeuTricoloreView: View {
    @StateObject private var vm = FeuViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Feu tricolore
            VStack(spacing: 12) {
                CercleFeu(color: .red, isActive: vm.state == .red)
                CercleFeu(color: .orange, isActive: vm.state == .orange)
                CercleFeu(color: .green, isActive: vm.state == .green)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
                    .shadow(radius: 8)
            )

            // Texte statut
            Text(statusText)
                .font(.headline)
                .foregroundColor(statusColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Barre de statut
            HStack {
                Text("Prochaine plage :")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(vm.prochainePlage)
                    .font(.caption.monospacedDigit())
                if !vm.compteARebours.isEmpty {
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(vm.compteARebours)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.orange)
                }
            }
            .padding(.bottom, 12)
        }
        .padding()
        .frame(minWidth: 280, maxWidth: 340, minHeight: 360, maxHeight: 420)
        .background(Color(.windowBackgroundColor))
    }

    private var statusText: String {
        switch vm.state {
        case .green:
            return "Off-Peak\nTarif normal"
        case .orange:
            return "Peak imminent\nPréparation"
        case .red:
            return "Peak actif\nTarif ×2"
        }
    }

    private var statusColor: Color {
        switch vm.state {
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FeuTricoloreView_Previews: PreviewProvider {
    static var previews: some View {
        FeuTricoloreView()
    }
}
#endif
