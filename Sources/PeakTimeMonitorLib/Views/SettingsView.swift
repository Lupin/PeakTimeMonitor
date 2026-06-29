import SwiftUI

// MARK: - Weekday helpers

extension PeakTimeSlot {
    var weekdayName: String {
        let names = ["", "Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]
        guard weekday >= 1 && weekday <= 7 else { return "Inconnu" }
        return names[weekday]
    }

    var timeRangeFormatted: String {
        String(format: "%02d:%02d – %02d:%02d", startHour, startMinute, endHour, endMinute)
    }
}

// MARK: - Row

struct SlotRowView: View {
    @Binding var slot: PeakTimeSlot
    let onDelete: () -> Void

    @State private var editing = false

    var body: some View {
        HStack(spacing: 8) {
            if editing {
                Picker("", selection: $slot.weekday) {
                    ForEach(1...7, id: \.self) { day in
                        let names = ["", "Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"]
                        Text(names[day]).tag(day)
                    }
                }
                .frame(width: 60)
                .labelsHidden()

                DatePicker("", selection: startBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .frame(width: 90)

                Text("–")
                    .foregroundColor(.secondary)

                DatePicker("", selection: endBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .frame(width: 90)

                Button("OK") { editing = false }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            } else {
                Text(slot.weekdayName)
                    .frame(width: 80, alignment: .leading)
                Text(slot.timeRangeFormatted)
                    .font(.body.monospacedDigit())
                Spacer()
                Button("Éditer") { editing = true }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
            }

            Button {
                onDelete()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var startBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: slot.startHour, minute: slot.startMinute)) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                slot = PeakTimeSlot(
                    weekday: slot.weekday,
                    startHour: comps.hour ?? slot.startHour,
                    startMinute: comps.minute ?? slot.startMinute,
                    endHour: slot.endHour,
                    endMinute: slot.endMinute
                )
            }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: slot.endHour, minute: slot.endMinute)) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                slot = PeakTimeSlot(
                    weekday: slot.weekday,
                    startHour: slot.startHour,
                    startMinute: slot.startMinute,
                    endHour: comps.hour ?? slot.endHour,
                    endMinute: comps.minute ?? slot.endMinute
                )
            }
        )
    }
}

// MARK: - Add sheet

struct AddSlotSheet: View {
    @State private var weekday = 2            // Monday by default
    @State private var startTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var endTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()

    let onAdd: (PeakTimeSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Ajouter un créneau")
                .font(.headline)

            Picker("Jour", selection: $weekday) {
                ForEach(1...7, id: \.self) { day in
                    let names = ["", "Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]
                    Text(names[day]).tag(day)
                }
            }
            .frame(width: 150)

            DatePicker("Début", selection: $startTime, displayedComponents: .hourAndMinute)
            DatePicker("Fin", selection: $endTime, displayedComponents: .hourAndMinute)

            HStack(spacing: 12) {
                Button("Annuler") { dismiss() }
                Button("Ajouter") {
                    let startComp = Calendar.current.dateComponents([.hour, .minute], from: startTime)
                    let endComp = Calendar.current.dateComponents([.hour, .minute], from: endTime)
                    let slot = PeakTimeSlot(
                        weekday: weekday,
                        startHour: startComp.hour ?? 8,
                        startMinute: startComp.minute ?? 0,
                        endHour: endComp.hour ?? 12,
                        endMinute: endComp.minute ?? 0
                    )
                    onAdd(slot)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 320, height: 260)
    }
}

// MARK: - Main settings view

public struct SettingsView: View {
    @State private var slots: [PeakTimeSlot] = []
    @State private var showAddSheet = false

    private let defaults = UserDefaults(suiteName: "group.peakmonitor")!
    private let defaultsKey = "peakTimeSlots"

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Créneaux Peak")
                .font(.title2)
                .bold()

            if slots.isEmpty {
                Text("Aucun créneau défini.")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                List {
                    ForEach($slots.indices, id: \.self) { index in
                        SlotRowView(slot: $slots[index]) {
                            slots.remove(at: index)
                            save()
                        }
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: 200)
            }

            HStack(spacing: 12) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Ajouter", systemImage: "plus.circle")
                }

                Spacer()

                Button("Réinitialiser") {
                    slots = PeakTimeSlot.defaultSlots
                    save()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .padding()
        .frame(minWidth: 460, minHeight: 320)
        .onAppear(perform: load)
        .onDisappear(perform: save)
        .sheet(isPresented: $showAddSheet) {
            AddSlotSheet { newSlot in
                slots.append(newSlot)
                save()
            }
        }
    }

    // MARK: - Persistence

    private func load() {
        if let saved = defaults.peakTimeSlots, !saved.isEmpty {
            slots = saved
        } else {
            slots = PeakTimeSlot.defaultSlots
        }
    }

    private func save() {
        defaults.peakTimeSlots = slots
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
