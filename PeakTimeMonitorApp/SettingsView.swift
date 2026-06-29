import SwiftUI

// MARK: - Day helpers

fileprivate let allDays: [(String, Int)] = [
    ("Tous les jours", 0), ("Lundi", 2), ("Mardi", 3), ("Mercredi", 4),
    ("Jeudi", 5), ("Vendredi", 6), ("Samedi", 7), ("Dimanche", 1)
]

fileprivate func dayLabel(_ w: Int) -> String {
    allDays.first(where: { $0.1 == w })?.0 ?? "?"
}

// MARK: - Extension

extension PeakTimeSlot {
    var weekdayName: String { dayLabel(weekday) }
    var timeRangeFormatted: String {
        String(format: "%02d:%02d – %02d:%02d", startHour, startMinute, endHour, endMinute)
    }
}

// MARK: - Time steppers

fileprivate struct TimeStepper: View {
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        HStack(spacing: 2) {
            Stepper("", value: $hour, in: 0...23)
                .labelsHidden()
                .scaleEffect(0.7)
            Text(String(format: "%02d", hour))
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 20)
            Text(":")
                .font(.system(size: 11)).foregroundColor(.secondary)
            Stepper("", value: $minute, in: 0...30, step: 30)
                .labelsHidden()
                .scaleEffect(0.7)
            Text(String(format: "%02d", minute))
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 20)
        }
    }
}

// MARK: - Read row

fileprivate struct ReadRow: View {
    let slot: PeakTimeSlot

    var body: some View {
        HStack(spacing: 0) {
            Text(slot.weekdayName)
                .frame(width: 100, alignment: .leading)
            Text(String(format: "%02d:%02d", slot.startHour, slot.startMinute))
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 44, alignment: .trailing)
            Text(" – ")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(String(format: "%02d:%02d", slot.endHour, slot.endMinute))
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 44, alignment: .leading)
        }
        .font(.system(size: 12))
    }
}

// MARK: - Edit row

fileprivate struct EditRow: View {
    @Binding var slot: PeakTimeSlot
    let onDelete: () -> Void

    @State private var weekday: Int = 0
    @State private var startH = 8; @State private var startM = 0
    @State private var endH = 12; @State private var endM = 0

    var body: some View {
        HStack(spacing: 0) {
            Button { onDelete() } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray).font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .frame(width: 22)

            Picker("", selection: $weekday) {
                ForEach(allDays, id: \.1) { d in Text(d.0).tag(d.1) }
            }
            .pickerStyle(.menu).labelsHidden()
            .frame(width: 130, alignment: .leading)

            TimeStepper(hour: $startH, minute: $startM)
            Text(" – ").font(.system(size: 11)).foregroundColor(.secondary)
            TimeStepper(hour: $endH, minute: $endM)
        }
        .font(.system(size: 12))
        .onAppear {
            weekday = slot.weekday
            startH = slot.startHour; startM = slot.startMinute
            endH = slot.endHour; endM = slot.endMinute
        }
        .onChange(of: weekday) { _, _ in slot.weekday = weekday }
        .onChange(of: startH) { _, _ in slot.startHour = startH }
        .onChange(of: startM) { _, _ in slot.startMinute = startM }
        .onChange(of: endH)   { _, _ in slot.endHour = endH }
        .onChange(of: endM)   { _, _ in slot.endMinute = endM }
    }
}

// MARK: - Add sheet

struct AddSlotSheet: View {
    @State private var weekday = 0
    @State private var startH = 8; @State private var startM = 0
    @State private var endH = 12; @State private var endM = 0

    let onAdd: (PeakTimeSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Ajouter un créneau").font(.headline)

            Picker("Jour", selection: $weekday) {
                ForEach(allDays, id: \.1) { d in Text(d.0).tag(d.1) }
            }
            .pickerStyle(.menu).frame(width: 160)

            HStack(spacing: 8) {
                TimeStepper(hour: $startH, minute: $startM)
                Text(" – ").font(.system(size: 13)).foregroundColor(.secondary)
                TimeStepper(hour: $endH, minute: $endM)
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
        .frame(width: 360, height: 220)
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
                            EditRow(slot: $slots[i]) { slots.remove(at: i) }
                        } else {
                            ReadRow(slot: slots[i])
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
        .frame(minWidth: 520, minHeight: 340)
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
