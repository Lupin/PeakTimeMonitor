import SwiftUI

// MARK: - Time slot helpers (30 min increments)

fileprivate let timeLabels: [String] = (0..<48).map { i in String(format: "%02d:%02d", i/2, (i%2)*30) }
fileprivate func timeSlot(_ idx: Int) -> (hour: Int, min: Int) { (idx/2, (idx%2)*30) }
fileprivate func timeIdx(hour: Int, minute: Int) -> Int {
    min(max(hour * 2 + (minute >= 30 ? 1 : 0), 0), 47)
}

// MARK: - Day helpers

fileprivate let allDays: [(label: String, value: Int)] = [
    ("Tous les jours", 0),
    ("Lundi",    2), ("Mardi",   3), ("Mercredi", 4),
    ("Jeudi",    5), ("Vendredi", 6), ("Samedi",  7),
    ("Dimanche", 1)
]

fileprivate func dayLabel(_ w: Int) -> String {
    allDays.first { $0.value == w }?.label ?? "?"
}

extension PeakTimeSlot {
    var weekdayName: String { dayLabel(weekday) }
    var timeRangeFormatted: String {
        String(format: "%02d:%02d – %02d:%02d", startHour, startMinute, endHour, endMinute)
    }
}

// MARK: - Layout constants

fileprivate let rowHeight: CGFloat   = 28
fileprivate let delW: CGFloat       = 24   // delete button
fileprivate let gap: CGFloat        = 8    // space between columns
fileprivate let colDay: CGFloat     = 110  // day label
fileprivate let colTime: CGFloat    = 52   // HH:MM picker
fileprivate let colDash: CGFloat    = 12   // "–"

// MARK: - Time Picker

struct MenuTimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        Menu {
            ForEach(0..<48, id: \.self) { i in
                Button {
                    hour = timeSlot(i).hour
                    minute = timeSlot(i).min
                } label: {
                    Text(timeLabels[i]).font(.system(size: 13, design: .monospaced))
                }
            }
        } label: {
            Text(String(format: "%02d:%02d", hour, minute))
                .font(.system(size: 13, design: .monospaced))
                .frame(width: colTime, alignment: .center)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

struct MenuDayPicker: View {
    @Binding var weekday: Int

    var body: some View {
        Menu {
            ForEach(allDays, id: \.value) { d in
                Button { weekday = d.value } label: { Text(d.label) }
            }
        } label: {
            Text(dayLabel(weekday))
                .frame(width: colDay, alignment: .leading)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

// MARK: - Table row (shared layout read + edit)

/// Une ligne de tableau : les colonnes sont toujours présentes mais
/// en lecture le bouton delete est invisible (pas juste caché → même espace).
struct SlotTableRow: View {
    @Binding var slot: PeakTimeSlot
    let isEditing: Bool
    let onDelete: (() -> Void)?

    @State private var weekday: Int = 0
    @State private var startH = 8; @State private var startM = 0
    @State private var endH = 12; @State private var endM = 0

    init(slot: Binding<PeakTimeSlot>, isEditing: Bool, onDelete: (() -> Void)? = nil) {
        self._slot = slot
        self.isEditing = isEditing
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(spacing: gap) {
            // Colonne 0 : bouton delete (ou espace réservé)
            if isEditing {
                Button { onDelete?() } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.gray).font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .frame(width: delW)
            } else {
                Spacer().frame(width: delW)
            }

            // Colonne 1 : jour
            if isEditing {
                MenuDayPicker(weekday: $weekday)
            } else {
                Text(slot.weekdayName)
                    .frame(width: colDay, alignment: .leading)
            }

            // Colonne 2 : heure début
            if isEditing {
                MenuTimePicker(hour: $startH, minute: $startM)
            } else {
                Text(String(format: "%02d:%02d", slot.startHour, slot.startMinute))
                    .font(.system(size: 13, design: .monospaced))
                    .frame(width: colTime, alignment: .center)
            }

            // Colonne 3 : tiret
            Text("–")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: colDash, alignment: .center)

            // Colonne 4 : heure fin
            if isEditing {
                MenuTimePicker(hour: $endH, minute: $endM)
            } else {
                Text(String(format: "%02d:%02d", slot.endHour, slot.endMinute))
                    .font(.system(size: 13, design: .monospaced))
                    .frame(width: colTime, alignment: .center)
            }
        }
        .frame(height: rowHeight)
        .font(.system(size: 13))
        .onAppear {
            weekday = slot.weekday
            startH = slot.startHour; startM = slot.startMinute
            endH = slot.endHour; endM = slot.endMinute
        }
        .onChange(of: weekday) { _, _ in slot.weekday = weekday }
        .onChange(of: startH) { _, _ in slot.startHour = startH }
        .onChange(of: startM) { _, _ in slot.startMinute = startM }
        .onChange(of: endH) { _, _ in slot.endHour = endH }
        .onChange(of: endM) { _, _ in slot.endMinute = endM }
    }
}

// MARK: - Add sheet

struct AddSlotSheet: View {
    @State private var startH = 8; @State private var startM = 0
    @State private var endH = 12; @State private var endM = 0
    @State private var weekday = 0

    let onAdd: (PeakTimeSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Ajouter un créneau").font(.headline)

            MenuDayPicker(weekday: $weekday)

            HStack(spacing: 6) {
                MenuTimePicker(hour: $startH, minute: $startM)
                Text("–").font(.system(size: 14)).foregroundColor(.secondary).frame(width: colDash)
                MenuTimePicker(hour: $endH, minute: $endM)
            }

            HStack(spacing: 12) {
                Button("Annuler") { dismiss() }
                Button("Ajouter") {
                    onAdd(PeakTimeSlot(weekday: weekday,
                                       startHour: startH, startMinute: startM,
                                       endHour: endH, endMinute: endM))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 340, height: 220)
    }
}

// MARK: - Main settings view

public struct SettingsView: View {
    @State private var slots: [PeakTimeSlot] = []
    @State private var showAddSheet = false
    @State private var isEditing = false
    private let defaults = UserDefaults(suiteName: "group.peakmonitor")!

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Créneaux Peak").font(.title3).bold()
                Spacer()
                Button(isEditing ? "Terminé" : "Modifier") {
                    isEditing.toggle()
                    if !isEditing { saveAndNotify() }
                }
                .buttonStyle(.bordered).controlSize(.small)
            }

            if slots.isEmpty {
                Text("Aucun créneau défini.").foregroundColor(.secondary).padding(.vertical, 20)
            } else {
                List {
                    ForEach(slots.indices, id: \.self) { i in
                        SlotTableRow(
                            slot: $slots[i],
                            isEditing: isEditing,
                            onDelete: isEditing ? { slots.remove(at: i) } : nil
                        )
                    }
                }
                .listStyle(.inset)
                .frame(minHeight: 180)
            }

            HStack {
                if isEditing {
                    Button { showAddSheet = true } label: {
                        Label("Ajouter", systemImage: "plus")
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
                Spacer()
                Button("Réinitialiser") {
                    slots = PeakTimeSlot.defaultSlots
                    isEditing = false
                    saveAndNotify()
                }
                .buttonStyle(.bordered).tint(.orange).controlSize(.small)
            }
        }
        .padding()
        .frame(minWidth: 560, minHeight: 340)
        .onAppear(perform: load)
        .onDisappear { if isEditing { isEditing = false; saveAndNotify() } }
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
        DistributedNotificationCenter.default().postNotificationName(NSNotification.Name("PeakTimeSlotsChanged"), object: nil, userInfo: nil, deliverImmediately: true)
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View { SettingsView() }
}
#endif
