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

// MARK: - Layout constants (shared widths so edit & read mode align)

fileprivate let colDay: CGFloat     = 110
fileprivate let colTime: CGFloat    = 52
fileprivate let colDash: CGFloat    = 16

// MARK: - Time Picker (Menu-based, fixed width)

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
                    Text(timeLabels[i])
                        .font(.system(size: 13, design: .monospaced))
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

// MARK: - Read-only slot label (same layout as edit row)

struct SlotLabel: View {
    let slot: PeakTimeSlot

    var body: some View {
        HStack(spacing: 0) {
            Text(slot.weekdayName)
                .frame(width: colDay, alignment: .leading)
            Text(slot.timeRangeFormatted)
                .frame(width: colTime + colDash + colTime, alignment: .center)
                .font(.system(size: 13, design: .monospaced))
                .offset(x: -8) // compensate for dash width
        }
        .font(.system(size: 12))
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
                        if isEditing {
                            EditSlotRow(slot: $slots[i]) { slots.remove(at: i) }
                        } else {
                            SlotLabel(slot: slots[i])
                        }
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
        .frame(minWidth: 540, minHeight: 340)
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

// MARK: - Edit row

struct EditSlotRow: View {
    @Binding var slot: PeakTimeSlot
    let onDelete: () -> Void

    @State private var weekday: Int = 0
    @State private var startH = 8; @State private var startM = 0
    @State private var endH = 12; @State private var endM = 0

    var body: some View {
        HStack(spacing: 0) {
            Button { onDelete() } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray).font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .frame(width: 28)

            MenuDayPicker(weekday: $weekday)

            MenuTimePicker(hour: $startH, minute: $startM)
            Text("–").font(.system(size: 12)).foregroundColor(.secondary).frame(width: colDash)
            MenuTimePicker(hour: $endH, minute: $endM)

            Spacer()
        }
        .padding(.vertical, 1)
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

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View { SettingsView() }
}
#endif
