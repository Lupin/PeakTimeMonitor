import SwiftUI

// MARK: - Weekday helpers

extension PeakTimeSlot {
    var weekdayName: String {
        if weekday == 0 { return "Lun–Ven" }
        return ["", "Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"][weekday]
    }

    var timeRangeFormatted: String {
        String(format: "%02d:%02d – %02d:%02d", startHour, startMinute, endHour, endMinute)
    }
}

// MARK: - Add sheet

struct AddSlotSheet: View {
    @State private var startHour = 8; @State private var startMin = 0
    @State private var endHour = 12; @State private var endMin = 0
    @State private var isAllWeekdays = true
    @State private var selectedWeekday = 2

    let onAdd: (PeakTimeSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            Text("Ajouter un créneau").font(.headline)

            Toggle("Tous les jours (lun–ven)", isOn: $isAllWeekdays)

            if !isAllWeekdays {
                Picker("Jour", selection: $selectedWeekday) {
                    ForEach(1...7, id: \.self) { d in
                        Text(["", "Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"][d]).tag(d)
                    }
                }
                .frame(width: 120)
            }

            HStack(spacing: 6) {
                TimePicker(hour: $startHour, minute: $startMin)
                Text("–").font(.system(size: 14)).foregroundColor(.secondary)
                TimePicker(hour: $endHour, minute: $endMin)
            }

            HStack(spacing: 10) {
                Button("Annuler") { dismiss() }
                Button("Ajouter") {
                    onAdd(PeakTimeSlot(weekday: isAllWeekdays ? 0 : selectedWeekday,
                                       startHour: startHour, startMinute: startMin,
                                       endHour: endHour, endMinute: endMin))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 320, height: 250)
    }
}

// MARK: - Reusable time picker (two compact Pickers)

struct TimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        HStack(spacing: 2) {
            Picker("", selection: $hour) {
                ForEach(0...23, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                        .font(.system(size: 11, design: .monospaced))
                }
            }
            .frame(width: 44)
            .labelsHidden()

            Text(":").font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)

            Picker("", selection: $minute) {
                ForEach(0...59, id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                        .font(.system(size: 11, design: .monospaced))
                }
            }
            .frame(width: 44)
            .labelsHidden()
        }
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
                Text("Aucun créneau défini.").foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                List {
                    ForEach(slots.indices, id: \.self) { i in
                        if isEditing {
                            SlotEditRow(slot: $slots[i]) {
                                slots.remove(at: i)
                            }
                        } else {
                            HStack {
                                Text(slots[i].weekdayName)
                                    .frame(width: 70, alignment: .leading)
                                    .font(.system(size: 12, weight: .medium))
                                Text(slots[i].timeRangeFormatted)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
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
        .frame(minWidth: 520, minHeight: 320)
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

// MARK: - Slot edit row (inline editing)

struct SlotEditRow: View {
    @Binding var slot: PeakTimeSlot
    let onDelete: () -> Void

    @State private var isAllWeekdays: Bool = true
    @State private var selectedWeekday = 2
    @State private var startH = 8; @State private var startM = 0
    @State private var endH = 12; @State private var endM = 0

    var body: some View {
        HStack(spacing: 8) {
            // Delete button on the left (Apple HIG standard)
            Button { onDelete() } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            // Day
            Text(slot.weekdayName)
                .frame(width: 70, alignment: .leading)
                .font(.system(size: 12, weight: .medium))

            // Time pickers
            TimePicker(hour: $startH, minute: $startM)
            Text("–").font(.system(size: 11)).foregroundColor(.secondary)
            TimePicker(hour: $endH, minute: $endM)

            Spacer()
        }
        .padding(.vertical, 2)
        .onAppear {
            startH = slot.startHour; startM = slot.startMinute
            endH = slot.endHour; endM = slot.endMinute
        }
        .onChange(of: startH) { _ in slot.startHour = startH }
        .onChange(of: startM) { _ in slot.startMinute = startM }
        .onChange(of: endH) { _ in slot.endHour = endH }
        .onChange(of: endM) { _ in slot.endMinute = endM }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View { SettingsView() }
}
#endif
