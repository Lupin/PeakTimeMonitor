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

// MARK: - Edit popover

struct EditSlotPopover: View {
    @Binding var slot: PeakTimeSlot
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var weekday: Int = 0
    @State private var isAllWeekdays: Bool = true
    @State private var startText: String = ""
    @State private var endText: String = ""

    var body: some View {
        VStack(spacing: 14) {
            Text("Modifier le créneau").font(.headline)

            Toggle("Tous les jours (lun–ven)", isOn: $isAllWeekdays)

            if !isAllWeekdays {
                Picker("Jour", selection: $weekday) {
                    ForEach(1...7, id: \.self) { d in
                        Text(["", "Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"][d]).tag(d)
                    }
                }
                .frame(width: 120)
            }

            HStack(spacing: 10) {
                TextField("HH:MM", text: $startText)
                    .frame(width: 65)
                    .font(.system(size: 13, design: .monospaced))
                Text("–")
                TextField("HH:MM", text: $endText)
                    .frame(width: 65)
                    .font(.system(size: 13, design: .monospaced))
            }

            HStack(spacing: 10) {
                Button("Annuler") { dismiss() }
                Button("Enregistrer") {
                    let s = parse(startText), e = parse(endText)
                    slot.weekday = isAllWeekdays ? 0 : weekday
                    slot.startHour = s.0; slot.startMinute = s.1
                    slot.endHour = e.0; slot.endMinute = e.1
                    onSave()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 280, height: 250)
        .onAppear {
            isAllWeekdays = slot.weekday == 0
            weekday = max(1, slot.weekday)
            startText = String(format: "%02d:%02d", slot.startHour, slot.startMinute)
            endText = String(format: "%02d:%02d", slot.endHour, slot.endMinute)
        }
    }

    private func parse(_ t: String) -> (Int, Int) {
        let p = t.replacingOccurrences(of: "h", with: ":").split(separator: ":").compactMap { Int($0) }
        return p.count == 2 && p[0] >= 0 && p[0] < 24 && p[1] >= 0 && p[1] < 60 ? (p[0], p[1]) : (8, 0)
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

            HStack(spacing: 10) {
                TextField("HH:MM", text: $startText)
                    .frame(width: 65)
                    .font(.system(size: 13, design: .monospaced))
                Text("–")
                TextField("HH:MM", text: $endText)
                    .frame(width: 65)
                    .font(.system(size: 13, design: .monospaced))
            }

            HStack(spacing: 10) {
                Button("Annuler") { dismiss() }
                Button("Ajouter") {
                    let sh = parse(startText), eh = parse(endText)
                    onAdd(PeakTimeSlot(weekday: isAllWeekdays ? 0 : selectedWeekday, startHour: sh.0, startMinute: sh.1, endHour: eh.0, endMinute: eh.1))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 280, height: 230)
    }

    private func parse(_ t: String) -> (Int, Int) {
        let p = t.replacingOccurrences(of: "h", with: ":").split(separator: ":").compactMap { Int($0) }
        return p.count == 2 && p[0] >= 0 && p[0] < 24 && p[1] >= 0 && p[1] < 60 ? (p[0], p[1]) : (8, 0)
    }
}

// MARK: - Main settings view

public struct SettingsView: View {
    @State private var slots: [PeakTimeSlot] = []
    @State private var showAddSheet = false
    @State private var isEditing = false
    @State private var editingIndex: Int?

    private let defaults = UserDefaults(suiteName: "group.peakmonitor")!

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Créneaux Peak").font(.title3).bold()
                Spacer()
                Button(isEditing ? "Terminé" : "Modifier") {
                    isEditing.toggle()
                    if !isEditing { editingIndex = nil; saveAndNotify() }
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
                            SlotEditRowView(slot: $slots[i]) {
                                slots.remove(at: i)
                            }
                        } else {
                            HStack {
                                Text(slots[i].weekdayName)
                                    .frame(width: 60, alignment: .leading)
                                    .font(.system(size: 12, weight: .medium))
                                Text(slots[i].timeRangeFormatted)
                                    .font(.system(size: 12, design: .monospaced))
                            }
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
                    saveAndNotify()
                }
                .buttonStyle(.bordered).tint(.orange).controlSize(.small)
            }
        }
        .padding()
        .frame(minWidth: 460, minHeight: 300)
        .onAppear(perform: load)
        .onDisappear { if isEditing { isEditing = false; saveAndNotify() } }
        .sheet(isPresented: $showAddSheet) {
            AddSlotSheet { s in slots.append(s); saveAndNotify() }
        }
        .sheet(item: $editingIndex) { index in
            EditSlotPopover(slot: $slots[index], onSave: { saveAndNotify() })
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

// MARK: - Slot row in edit mode

struct SlotEditRowView: View {
    @Binding var slot: PeakTimeSlot
    let onDelete: () -> Void

    @State private var startText: String = ""
    @State private var endText: String = ""

    var body: some View {
        HStack(spacing: 8) {
            // Day picker
            Text(slot.weekdayName)
                .frame(width: 60, alignment: .leading)
                .font(.system(size: 12, weight: .medium))

            // Time fields
            TextField("HH:MM", text: $startText)
                .frame(width: 55)
                .font(.system(size: 11, design: .monospaced))
            Text("–").font(.system(size: 11)).foregroundColor(.secondary)
            TextField("HH:MM", text: $endText)
                .frame(width: 55)
                .font(.system(size: 11, design: .monospaced))

            Spacer()

            Button { onDelete() } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .onAppear {
            startText = String(format: "%02d:%02d", slot.startHour, slot.startMinute)
            endText = String(format: "%02d:%02d", slot.endHour, slot.endMinute)
        }
        .onChange(of: startText) { _ in parseStart() }
        .onChange(of: endText) { _ in parseEnd() }
    }

    private func parseStart() {
        let p = startText.replacingOccurrences(of: "h", with: ":").split(separator: ":").compactMap { Int($0) }
        if p.count == 2, p[0] >= 0 && p[0] < 24, p[1] >= 0 && p[1] < 60 {
            slot.startHour = p[0]; slot.startMinute = p[1]
        }
    }

    private func parseEnd() {
        let p = endText.replacingOccurrences(of: "h", with: ":").split(separator: ":").compactMap { Int($0) }
        if p.count == 2, p[0] >= 0 && p[0] < 24, p[1] >= 0 && p[1] < 60 {
            slot.endHour = p[0]; slot.endMinute = p[1]
        }
    }
}

// Conformance for .sheet(item:)
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View { SettingsView() }
}
#endif
