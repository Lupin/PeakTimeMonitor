import SwiftUI

// MARK: - Time slot helpers (15 min increments)

/// Liste des 96 créneaux de 15 min sur une journée, formatés "HH:MM"
fileprivate let timeLabels: [String] = (0..<96).map { i in String(format: "%02d:%02d", i/4, (i%4)*15) }
/// Convertit un index (0–95, par pas de 15 min) en (heure, minute)
fileprivate func timeSlot(_ idx: Int) -> (hour: Int, min: Int) { (idx/4, (idx%4)*15) }
/// Convertit (heure, minute) en index dans la liste timeLabels (0–95, borné)
fileprivate func timeIdx(hour: Int, minute: Int) -> Int {
    min(max(hour * 4 + minute / 15, 0), 95)
}

// MARK: - Day helpers

/// Paires (label affiché, valeur weekday) pour le sélecteur de jour de semaine.
/// weekday: 0 = tous les jours (lun-ven), 1 = dimanche, 2 = lundi, …, 7 = samedi
fileprivate let allDays: [(label: String, value: Int)] = [
    (String(localized: "All days"), 0),
    (String(localized: "Monday"),    2), (String(localized: "Tuesday"),   3), (String(localized: "Wednesday"), 4),
    (String(localized: "Thursday"),    5), (String(localized: "Friday"), 6), (String(localized: "Saturday"),  7),
    (String(localized: "Sunday"), 1)
]

/// Retourne le nom du jour lisible correspondant à une valeur weekday
fileprivate func dayLabel(_ w: Int) -> String {
    allDays.first { $0.value == w }?.label ?? "?"
}

extension PeakTimeSlot {
    /// Nom lisible du jour de semaine, ex: "Lundi" ou "Tous les jours"
    var weekdayName: String { dayLabel(weekday) }
    /// Plage horaire formatée "HH:MM – HH:MM"
    var timeRangeFormatted: String {
        String(format: "%02d:%02d – %02d:%02d", startHour, startMinute, endHour, endMinute)
    }
}
/// Largeurs fixes pour aligner les colonnes de la liste de créneaux
fileprivate let rowHeight: CGFloat   = 28
fileprivate let delW: CGFloat       = 28   // delete button (24 icon + 4 gap)
fileprivate let colDay: CGFloat     = 110  // day label
fileprivate let colTime: CGFloat    = 52   // HH:MM picker
fileprivate let colDash: CGFloat    = 14   // "–"

// MARK: - Time Picker (Menu-based, fixed width)

/// Sélecteur horaire basé sur un `Menu` avec incréments de 15 minutes.
/// Affiche l'heure choisie dans un cadre de largeur fixe pour un alignement
/// cohérent avec le reste de la liste.
struct MenuTimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    /// Lit le format depuis UserDefaults (App Group)
    private var use24Hour: Bool {
        UserDefaults(suiteName: "group.peakmonitor")?.use24Hour ?? true
    }

    /// Génère le label d'une tranche horaire selon le format 24h/12h
    private func labelFor(_ i: Int) -> String {
        let (h, m) = timeSlot(i)
        if use24Hour {
            return String(format: "%02d:%02d", h, m)
        } else {
            let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
            let ampm = h < 12 ? String(localized: "AM") : String(localized: "PM")
            return String(format: "%d:%02d %@", h12, m, ampm)
        }
    }

    var body: some View {
        Menu {
            ForEach(0..<96, id: \.self) { i in
                Button {
                    hour = timeSlot(i).hour
                    minute = timeSlot(i).min
                } label: {
                    Text(labelFor(i))
                        .font(.system(size: 13, design: .monospaced))
                }
            }
        } label: {
            Text(labelFor(timeIdx(hour: hour, minute: minute)))
                .font(.system(size: 13, design: .monospaced))
                .frame(width: colTime, alignment: .center)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

/// Sélecteur de jour de semaine basé sur un `Menu`.
struct MenuDayPicker: View {
    /// Jour sélectionné (0 = tous les jours, 1 = dimanche, …, 7 = samedi)
    @Binding var weekday: Int

    var body: some View {
        Menu {
            ForEach(allDays, id: \.value) { d in
                Button { weekday = d.value } label: { Text(d.label) }
            }
        } label: {
            Text(dayLabel(weekday))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .menuStyle(.borderlessButton)
        .frame(width: colDay, alignment: .trailing)
        .fixedSize()
    }
}

// MARK: - Read-only slot label (same layout as edit row)

/// Ligne en lecture seule affichant un créneau, avec la même disposition que `EditSlotRow`
/// pour éviter les sauts visuels au passage en mode édition.
struct SlotLabel: View {
    let slot: PeakTimeSlot

    var body: some View {
        HStack(spacing: 0) {
            // Reserve space for delete button
            Color.clear.frame(width: delW)
            Text(slot.weekdayName)
                .frame(width: colDay, alignment: .leading)
            Text(String(format: "%02d:%02d", slot.startHour, slot.startMinute))
                .font(.system(size: 13, design: .monospaced))
                .frame(width: colTime, alignment: .center)
            Text(String(localized: "–"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: colDash, alignment: .center)
            Text(String(format: "%02d:%02d", slot.endHour, slot.endMinute))
                .font(.system(size: 13, design: .monospaced))
                .frame(width: colTime, alignment: .center)
        }
        .font(.system(size: 13))
    }
}

// MARK: - Add sheet

/// Sheet modale pour ajouter un nouveau créneau peak.
/// Présente un sélecteur de jour, un sélecteur d'heure de début et de fin,
/// et les boutons Ajouter/Annuler.
struct AddSlotSheet: View {
    /// Heure de début par défaut : 08:00
    @State private var startH = 8; @State private var startM = 0
    /// Heure de fin par défaut : 12:00
    @State private var endH = 12; @State private var endM = 0
    /// Jour par défaut : tous les jours
    @State private var weekday = 0

    /// Callback appelé avec le nouveau créneau quand l'utilisateur appuie sur Ajouter
    let onAdd: (PeakTimeSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: "Add a slot")).font(.headline)

            MenuDayPicker(weekday: $weekday)

            HStack(spacing: 6) {
                MenuTimePicker(hour: $startH, minute: $startM)
                Text(String(localized: "–")).font(.system(size: 14)).foregroundColor(.secondary).frame(width: colDash)
                MenuTimePicker(hour: $endH, minute: $endM)
            }

            HStack(spacing: 12) {
                Button(String(localized: "Cancel")) { dismiss() }
                Button(String(localized: "Add")) {
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

/// Vue des préférences : gestion des créneaux peak, délai d'alerte orange,
/// ajout/suppression/modification de créneaux, et réinitialisation aux valeurs par défaut.
public struct SettingsView: View {
    /// Liste des créneaux peak éditée par l'utilisateur
    @State private var slots: [PeakTimeSlot] = []
    /// Contrôle l'affichage de la sheet d'ajout de créneau
    @State private var showAddSheet = false
    /// Bascule entre le mode lecture et le mode édition de la liste
    @State private var isEditing = false
    /// Délai en minutes avant un peak pour déclencher l'alerte orange
    @State private var orangeMinutes: Int = 15
    /// Label personnalisé affiché au-dessus du feu
    @State private var peakLabel: String = "DeepSeek"
    /// Format d'heure : true = 24h, false = 12h (AM/PM)
    @State private var use24Hour: Bool = true
    /// UserDefaults partagé avec l'icône de barre de statut
    private let defaults = UserDefaults(suiteName: "group.peakmonitor")!

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Peak Slots")).font(.title3).bold()
                Spacer()
                Button(isEditing ? String(localized: "Done") : String(localized: "Edit")) {
                    isEditing.toggle()
                    if !isEditing { saveAndNotify() }
                }
                .buttonStyle(.bordered).controlSize(.small)
            }

            // Label personnalisé
            HStack {
                Text(String(localized: "Label:")).font(.system(size: 12))
                TextField(String(localized: "Enter label"), text: $peakLabel)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    .onSubmit { saveAndNotify() }
            }

            // Format d'heure 24h / 12h
            HStack {
                Text(String(localized: "Time format:")).font(.system(size: 12))
                Picker("", selection: $use24Hour) {
                    Text(String(localized: "24h")).tag(true)
                    Text(String(localized: "12h (AM/PM)")).tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 160)
                .onChange(of: use24Hour) { _, _ in saveAndNotify() }
            }

            // Orange delay setting
            HStack {
                Text(String(localized: "Orange alert:")).font(.system(size: 12))
                Picker("", selection: $orangeMinutes) {
                    Text(String(localized: "5 min")).tag(5)
                    Text(String(localized: "10 min")).tag(10)
                    Text(String(localized: "15 min")).tag(15)
                    Text(String(localized: "20 min")).tag(20)
                    Text(String(localized: "30 min")).tag(30)
                    Text(String(localized: "45 min")).tag(45)
                    Text(String(localized: "60 min")).tag(60)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .onChange(of: orangeMinutes) { _, _ in saveAndNotify() }
            }

            if slots.isEmpty {
                Text(String(localized: "No slots defined.")).foregroundColor(.secondary).padding(.vertical, 20)
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
                        Label(String(localized: "Add"), systemImage: "plus")
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
                Spacer()
                Button(String(localized: "Reset")) {
                    slots = PeakTimeSlot.defaultSlots
                    isEditing = false
                    saveAndNotify()
                }
                .buttonStyle(.bordered).tint(.orange).controlSize(.small)
            }

            // Version
            Text(String(localized: "PeakTimeMonitor") + " " + appVersion)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(minWidth: 540, minHeight: 420)
        .onAppear(perform: load)
        .onDisappear { if isEditing { isEditing = false; saveAndNotify() } }
        .sheet(isPresented: $showAddSheet) {
            AddSlotSheet { s in slots.append(s); saveAndNotify() }
        }
    }

    /// Charge les créneaux et le délai orange depuis UserDefaults,
    /// avec fallback sur les valeurs par défaut si rien n'est sauvegardé
    private func load() {
        if let saved = defaults.peakTimeSlots, !saved.isEmpty { slots = saved }
        else { slots = PeakTimeSlot.defaultSlots }
        let om = defaults.orangeMinutes
        orangeMinutes = om > 0 ? om : 15
        peakLabel = defaults.peakLabel
        use24Hour = defaults.use24Hour
    }

    /// Persiste les créneaux et le délai orange dans UserDefaults,
    /// puis envoie une notification distribuée pour informer l'icône de barre de statut
    private func saveAndNotify() {
        defaults.peakTimeSlots = slots
        defaults.orangeMinutes = orangeMinutes
        defaults.peakLabel = peakLabel
        defaults.use24Hour = use24Hour
        defaults.synchronize()
        DistributedNotificationCenter.default().postNotificationName(NSNotification.Name("PeakTimeSlotsChanged"), object: nil, userInfo: nil, deliverImmediately: true)
    }

    /// Version de l'app lue depuis le bundle, ex: "v1.2.3"
    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "v\(v)"
    }
}

// MARK: - Edit row

/// Ligne d'édition d'un créneau dans la liste.
///
/// Contient un bouton de suppression (cercle rouge), un `MenuDayPicker` pour le jour,
/// et deux `MenuTimePicker` pour les heures de début et de fin. Les modifications
/// sont synchronisées immédiatement sur le binding `slot`.
struct EditSlotRow: View {
    /// Le créneau édité, modifié en temps réel via les bindings
    @Binding var slot: PeakTimeSlot
    /// Action déclenchée quand l'utilisateur appuie sur le bouton de suppression
    let onDelete: () -> Void

    /// Copie locale du jour, synchronisée avec `slot.weekday` à l'apparition et via onChange
    @State private var weekday: Int = 0
    /// Copie locale de l'heure/minutes de début
    @State private var startH = 8; @State private var startM = 0
    /// Copie locale de l'heure/minutes de fin
    @State private var endH = 12; @State private var endM = 0

    var body: some View {
        HStack(spacing: 0) {
            Button { onDelete() } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray).font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .frame(width: delW)

            // Day — same width as read mode, Menu inside a fixed frame
            MenuDayPicker(weekday: $weekday)
                .frame(width: colDay, alignment: .leading)

            Spacer().frame(width: 4)

            MenuTimePicker(hour: $startH, minute: $startM)
            Text(String(localized: "–")).font(.system(size: 13)).foregroundColor(.secondary).frame(width: colDash, alignment: .center)
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
