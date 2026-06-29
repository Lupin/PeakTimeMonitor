import SwiftUI

// MARK: - Weekday helpers

extension PeakTimeSlot {
    var weekdayName: String {
        ["", "Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"][weekday]
    }

    var timeRangeFormatted: String {
        String(format: "%02d:%02d – %02d:%02d", startHour, startMinute, endHour, endMinute)
    }

    /// Retourne true si ce créneau couvre tous les jours (lun-ven)
    var isAllWeekdays: Bool {
        weekday == 0
    }

    /// Si weekday == 0, le slot s'applique à tous les jours lun-ven
    func matches(weekday: Int) -> Bool {
        self.weekday == 0 || self.weekday == weekday
    }
}

// MARK: - Row

struct SlotRowView: View {
    @Binding var slot: PeakTimeSlot
    let onDelete: () -> Void
    @State private var editing = false

    // Champs texte pour l'heure
    @State private var startText: String = ""
    @State private var endText: String = ""

    var body: some View {
        HStack(spacing: 6) {
            if editing {
                TextField("HH:MM", text: $startText)
                    .frame(width: 45)
                    .font(.system(size: 11, design: .monospaced))
                Text("–").font(.system(size: 11)).foregroundColor(.secondary)
                TextField("HH:MM", text: $endText)
                    .frame(width: 45)
                    .font(.system(size: 11, design: .monospaced))
                Button("OK") {
                    parseAndSave()
                    editing = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .font(.system(size: 10))
            } else {
                Text(slot.weekdayName)
                    .frame(width: 30, alignment: .leading)
                    .font(.system(size: 11))
                Text(slot.timeRangeFormatted)
                    .font(.system(size: 11, design: .monospaced))
                Spacer()
                Button("Éd") {
                    startText = String(format: "%02d:%02d", slot.startHour, slot.startMinute)
                    endText = String(format: "%02d:%02d", slot.endHour, slot.endMinute)
                    editing = true
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .font(.system(size: 10))
            }

            Button { onDelete() } label: {
                Image(systemName: "minus.circle.fill").foregroundColor(.red).font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .onAppear {
            startText = String(format: "%02d:%02d", slot.startHour, slot.startMinute)
            endText = String(format: "%02d:%02d", slot.endHour, slot.endMinute)
        }
    }

    private func parseTime(_ text: String) -> (hour: Int, minute: Int)? {
        let parts = text.replacingOccurrences(of: "h", with: ":").split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, parts[0] >= 0 && parts[0] < 24, parts[1] >= 0 && parts[1] < 60 else { return nil }
        return (parts[0], parts[1])
    }

    private func parseAndSave() {
        if let s = parseTime(startText), let e = parseTime(endText) {
            slot.startHour = s.hour
            slot.startMinute = s.minute
            slot.endHour = e.hour
            slot.endMinute = e.minute
        }
    }
}

// MARK: - Add sheet

struct AddSlotSheet: View {
    @State private var startText = "08:00"
    @State private var endText = "12:00"
    @State private var isAllWeekdays = true
    @State private var selectedWeekday = 2

    let onAdd: (PeakTimeSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text("Ajouter un créneau").font(.headline)

            Toggle("Tous les jours (lun-ven)", isOn: $isAllWeekdays)
                .font(.system(size: 11))

            if !isAllWeekdays {
                Picker("Jour", selection: $selectedWeekday) {
                    ForEach(1...7, id: \.self) { d in
                        Text(["", "Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"][d]).tag(d)
                    }
                }
                .frame(width: 120)
            }

            HStack(spacing: 8) {
                TextField("HH:MM", text: $startText)
                    .frame(width: 60)
                    .font(.system(size: 13, design: .monospaced))
                Text("–")
                TextField("HH:MM", text: $endText)
                    .frame(width: 60)
                    .font(.system(size: 13, design: .monospaced))
            }

            HStack(spacing: 8) {
                Button("Annuler") { dismiss() }
                Button("Ajouter") {
                    let sh = parseTime(startText), eh = parseTime(endText)
                    let slot = PeakTimeSlot(
                        weekday: isAllWeekdays ? 0 : selectedWeekday,
                        startHour: sh.0, startMinute: sh.1,
                        endHour: eh.0, endMinute: eh.1
                    )
                    onAdd(slot)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 280, height: 220)
    }

    private func parseTime(_ t: String) -> (Int, Int) {
        let p = t.replacingOccurrences(of: "h", with: ":").split(separator: ":").compactMap { Int($0) }
        return (p.count == 2 && p[0] >= 0 && p[0] < 24 && p[1] >= 0 && p[1] < 60 ? (p[0], p[1]) : (8, 0))
    }
}

// MARK: - Main settings view

public struct SettingsView: View {
    @State private var slots: [PeakTimeSlot] = []
    @State private var showAddSheet = false

    private let defaults = UserDefaults(suiteName: "group.peakmonitor")!

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Créneaux Peak").font(.title2).bold()

            if slots.isEmpty {
                Text("Aucun créneau défini.").foregroundColor(.secondary)
            } else {
                List {
                    ForEach($slots.indices, id: \.self) { i in
                        SlotRowView(slot: $slots[i]) {
                            slots.remove(at: i)
                            saveAndNotify()
                        }
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: 160)
            }

            HStack(spacing: 10) {
                Button { showAddSheet = true } label: { Label("Ajouter", systemImage: "plus.circle") }
                Spacer()
                Button("Réinitialiser") { slots = PeakTimeSlot.defaultSlots; saveAndNotify() }
                    .buttonStyle(.bordered).tint(.orange).controlSize(.small)
            }
        }
        .padding()
        .frame(minWidth: 360, minHeight: 280)
        .onAppear(perform: load)
        .sheet(isPresented: $showAddSheet) {
            AddSlotSheet { s in slots.append(s); saveAndNotify() }
        }
    }

    private func load() {
        if let saved = defaults.peakTimeSlots, !saved.isEmpty { slots = saved }
        else { slots = PeakTimeSlot.defaultSlots }
    }

    private func saveAndNotify() {
        defaults.peakTimeSlots = slots
        defaults.synchronize()
        // Notifier l'app principale via notification center (inter-process)
        DistributedNotificationCenter.default().postNotificationName(NSNotification.Name("PeakTimeSlotsChanged"), object: nil, userInfo: nil, deliverImmediately: true)
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View { SettingsView() }
}
#endif
