import SwiftUI

// MARK: - Time slot helpers

/// 48 slots de 30 minutes : "00:00", "00:30", "01:00", ... "23:30"
fileprivate let timeSlots: [(label: String, hour: Int, min: Int)] = {
    (0..<48).map { i in
        let h = i / 2
        let m = (i % 2) * 30
        return (String(format: "%02d:%02d", h, m), h, m)
    }
}()

fileprivate func timeIndex(hour: Int, minute: Int) -> Int {
    let idx = hour * 2 + (minute >= 30 ? 1 : 0)
    return min(max(idx, 0), 47)
}

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
    @State private var startIndex = timeIndex(hour: 8, minute: 0)
    @State private var endIndex = timeIndex(hour: 12, minute: 0)
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

            HStack(spacing: 8) {
                Picker("Début", selection: $startIndex) {
                    ForEach(0..<48, id: \.self) { i in
                        Text(timeSlots[i].label)
                            .tag(i)
                            .font(.system(size: 12, design: .monospaced))
                    }
                }
                .frame(width: 65)
                .clipped()

                Text("–").font(.system(size: 14)).foregroundColor(.secondary)

                Picker("Fin", selection: $endIndex) {
                    ForEach(0..<48, id: \.self) { i in
                        Text(timeSlots[i].label)
                            .tag(i)
                            .font(.system(size: 12, design: .monospaced))
                    }
                }
                .frame(width: 65)
                .clipped()
            }

            HStack(spacing: 10) {
                Button("Annuler") { dismiss() }
                Button("Ajouter") {
                    let s = timeSlots[startIndex], e = timeSlots[endIndex]
                    onAdd(PeakTimeSlot(weekday: isAllWeekdays ? 0 : selectedWeekday,
                                       startHour: s.hour, startMinute: s.min,
                                       endHour: e.hour, endMinute: e.min))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300, height: 260)
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
                            EditSlotRow(slot: $slots[i]) {
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

// MARK: - Edit row

struct EditSlotRow: View {
    @Binding var slot: PeakTimeSlot
    let onDelete: () -> Void

    @State private var startIdx: Int = 0
    @State private var endIdx: Int = 0

    var body: some View {
        HStack(spacing: 8) {
            Button { onDelete() } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            Text(slot.weekdayName)
                .frame(width: 70, alignment: .leading)
                .font(.system(size: 12, weight: .medium))

            Picker("", selection: $startIdx) {
                ForEach(0..<48, id: \.self) { i in
                    Text(timeSlots[i].label)
                        .font(.system(size: 11, design: .monospaced))
                        .tag(i)
                }
            }
            .frame(width: 60)
            .clipped()

            Text("–").font(.system(size: 11)).foregroundColor(.secondary)

            Picker("", selection: $endIdx) {
                ForEach(0..<48, id: \.self) { i in
                    Text(timeSlots[i].label)
                        .font(.system(size: 11, design: .monospaced))
                        .tag(i)
                }
            }
            .frame(width: 60)
            .clipped()

            Spacer()
        }
        .padding(.vertical, 2)
        .onAppear {
            startIdx = timeIndex(hour: slot.startHour, minute: slot.startMinute)
            endIdx = timeIndex(hour: slot.endHour, minute: slot.endMinute)
        }
        .onChange(of: startIdx) { _ in
            let s = timeSlots[startIdx]
            slot.startHour = s.hour; slot.startMinute = s.min
        }
        .onChange(of: endIdx) { _ in
            let e = timeSlots[endIdx]
            slot.endHour = e.hour; slot.endMinute = e.min
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View { SettingsView() }
}
#endif
