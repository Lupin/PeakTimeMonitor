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
    ("Lundi", 2), ("Mardi", 3), ("Mercredi", 4),
    ("Jeudi", 5), ("Vendredi", 6), ("Samedi", 7),
    ("Dimanche", 1)
]

fileprivate func dayLabel(_ w: Int) -> String {
    allDays.first { $0.value == w }?.label ?? "?"
}

// MARK: - Layout constants

fileprivate let delW: CGFloat   = 24
fileprivate let colDay: CGFloat = 110
fileprivate let colTime: CGFloat = 56
fileprivate let colDash: CGFloat = 14

// MARK: - Table row

struct SlotTableRow: View {
    @Binding var slot: PeakTimeSlot
    let isEditing: Bool
    let onDelete: (() -> Void)?

    @State private var weekday: Int = 0
    @State private var startIdx = timeIdx(hour: 8, minute: 0)
    @State private var endIdx   = timeIdx(hour: 12, minute: 0)

    var body: some View {
        HStack(spacing: 0) {
            // Delete button (or spacer)
            if isEditing {
                Button { onDelete?() } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.gray).font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .frame(width: delW)
            } else {
                Color.clear.frame(width: delW)
            }

            // Day
            if isEditing {
                Picker("", selection: $weekday) {
                    ForEach(allDays, id: \.value) { d in
                        Text(d.label).tag(d.value)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: colDay)
                .clipped()
            } else {
                Text(dayLabel(slot.weekday))
                    .frame(width: colDay, alignment: .leading)
            }

            // Time start
            if isEditing {
                Picker("", selection: $startIdx) {
                    ForEach(0..<48, id: \.self) { i in
                        Text(timeLabels[i])
                            .font(.system(size: 12, design: .monospaced))
                            .tag(i)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: colTime)
                .clipped()
            } else {
                Text(String(format: "%02d:%02d", slot.startHour, slot.startMinute))
                    .font(.system(size: 13, design: .monospaced))
                    .frame(width: colTime, alignment: .center)
            }

            // Dash
            Text("–")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: colDash, alignment: .center)

            // Time end
            if isEditing {
                Picker("", selection: $endIdx) {
                    ForEach(0..<48, id: \.self) { i in
                        Text(timeLabels[i])
                            .font(.system(size: 12, design: .monospaced))
                            .tag(i)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: colTime)
                .clipped()
            } else {
                Text(String(format: "%02d:%02d", slot.endHour, slot.endMinute))
                    .font(.system(size: 13, design: .monospaced))
                    .frame(width: colTime, alignment: .center)
            }
        }
        .font(.system(size: 13))
        .frame(height: 28)
        .onAppear {
            weekday = slot.weekday
            startIdx = timeIdx(hour: slot.startHour, minute: slot.startMinute)
            endIdx   = timeIdx(hour: slot.endHour, minute: slot.endMinute)
        }
        .onChange(of: weekday)  { _, _ in slot.weekday = weekday }
        .onChange(of: startIdx) { _, _ in
            let s = timeSlot(startIdx); slot.startHour = s.hour; slot.startMinute = s.min
        }
        .onChange(of: endIdx) { _, _ in
            let e = timeSlot(endIdx); slot.endHour = e.hour; slot.endMinute = e.min
        }
    }
}

// MARK: - Add sheet

struct AddSlotSheet: View {
    @State private var startIdx = timeIdx(hour: 8, minute: 0)
    @State private var endIdx   = timeIdx(hour: 12, minute: 0)
    @State private var weekday  = 0

    let onAdd: (PeakTimeSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Ajouter un créneau").font(.headline)

            Picker("Jour", selection: $weekday) {
                ForEach(allDays, id: \.value) { d in
                    Text(d.label).tag(d.value)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 160)

            HStack(spacing: 8) {
                Picker("Début", selection: $startIdx) {
                    ForEach(0..<48, id: \.self) { i in
                        Text(timeLabels[i])
                            .font(.system(size: 14, design: .monospaced))
                            .tag(i)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 72)
                .clipped()

                Text("–").font(.system(size: 14)).foregroundColor(.secondary)

                Picker("Fin", selection: $endIdx) {
                    ForEach(0..<48, id: \.self) { i in
                        Text(timeLabels[i])
                            .font(.system(size: 14, design: .monospaced))
                            .tag(i)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 72)
                .clipped()
            }

            HStack(spacing: 12) {
                Button("Annuler") { dismiss() }
                Button("Ajouter") {
                    let s = timeSlot(startIdx), e = timeSlot(endIdx)
                    onAdd(PeakTimeSlot(weekday: weekday,
                                       startHour: s.hour, startMinute: s.min,
                                       endHour: e.hour, endMinute: e.min))
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
