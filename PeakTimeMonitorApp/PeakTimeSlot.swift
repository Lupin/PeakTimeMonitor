import Foundation

/// Représente un créneau horaire de peak tarifaire.
///
/// - `weekday` : 0 = tous les jours ouvrables (lun–ven), 1 = dimanche, 2–7 = lundi–samedi
/// - Les heures et minutes sont en valeurs entières (0–23 et 0–59)
public struct PeakTimeSlot: Codable, Equatable, Sendable {
    /// Jour de la semaine (0 = lun–ven, 1 = dimanche, 2–7 = lundi–samedi)
    public var weekday: Int
    /// Heure de début du créneau (0–23)
    public var startHour: Int
    /// Minute de début du créneau (0–59)
    public var startMinute: Int
    /// Heure de fin du créneau (0–23)
    public var endHour: Int
    /// Minute de fin du créneau (0–59)
    public var endMinute: Int

    public init(weekday: Int, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        self.weekday = weekday
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }
}

/// État du feu tricolore correspondant à la situation tarifaire courante.
/// - `.green`  : off-peak, tarif normal
/// - `.orange` : peak imminent (dans moins de N minutes), préparation
/// - `.red`    : peak actif, tarif majoré
public enum FeuState: String, Equatable {
    case green
    case orange
    case red
}

public extension PeakTimeSlot {
    /// Créneaux par défaut pour le tarif DeepSeek à Paris : 3h–6h et 8h–12h, lundi à vendredi.
    /// Utilise `weekday=0` (tous les jours ouvrables) pour n'avoir que 2 créneaux au lieu de 10.
    static let defaultSlots: [PeakTimeSlot] = [
        PeakTimeSlot(weekday: 0, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0),
        PeakTimeSlot(weekday: 0, startHour: 8, startMinute: 0, endHour: 12, endMinute: 0)
    ]

    /// Détermine l'état courant du feu tricolore en fonction des créneaux et du délai orange.
    ///
    /// Parcourt les créneaux du jour courant pour déterminer si l'on est :
    /// - en plein peak (`.red`)
    /// - dans la fenêtre d'alerte avant un peak (`.orange`)
    /// - en dehors de tout peak (`.green`)
    ///
    /// - Parameters:
    ///   - slots: Liste des créneaux peak à évaluer
    ///   - orangeMinutes: Minutes avant le début d'un peak pour passer en orange (défaut: 15)
    /// - Returns: L'état du feu correspondant
    static func currentState(slots: [PeakTimeSlot], orangeMinutes: Int = 15) -> FeuState {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute

        // Filter slots for today: weekday match OR weekday==0 (all weekdays Mon-Fri)
        let todaySlots = slots.filter { $0.weekday == weekday || ($0.weekday == 0 && weekday >= 2 && weekday <= 6) }

        // Check if we're inside an active peak
        for slot in todaySlots {
            let startMinutes = slot.startHour * 60 + slot.startMinute
            let endMinutes = slot.endHour * 60 + slot.endMinute
            if currentMinutes >= startMinutes && currentMinutes < endMinutes {
                return .red
            }
        }

        // Check if a peak starts within orangeMinutes
        for slot in todaySlots {
            let startMinutes = slot.startHour * 60 + slot.startMinute
            let diff = startMinutes - currentMinutes
            if diff > 0 && diff <= orangeMinutes {
                return .orange
            }
        }

        return .green
    }
}

// MARK: - UserDefaults Integration

extension UserDefaults {
    /// Clé de stockage des créneaux peak dans UserDefaults (encodés en JSON)
    private static let peakTimeSlotsKey = "peakTimeSlots"
    /// Clé de stockage du délai d'alerte orange en minutes
    private static let orangeMinutesKey = "orangeMinutes"
    /// Clé de stockage du label personnalisé
    private static let peakLabelKey = "peakLabel"
    /// Clé de stockage du format horaire (24h ou 12h)
    private static let use24HourKey = "use24Hour"

    /// Liste des créneaux peak sauvegardés, encodée/décodée en JSON.
    /// Retourne `nil` si aucune donnée n'est présente pour la clé.
    public var peakTimeSlots: [PeakTimeSlot]? {
        get {
            guard let data = data(forKey: Self.peakTimeSlotsKey) else { return nil }
            return try? JSONDecoder().decode([PeakTimeSlot].self, from: data)
        }
        set {
            if let newValue = newValue {
                let data = try? JSONEncoder().encode(newValue)
                set(data, forKey: Self.peakTimeSlotsKey)
            } else {
                removeObject(forKey: Self.peakTimeSlotsKey)
            }
        }
    }

    /// Délai d'alerte orange en minutes. Valeur par défaut : 0 (pas d'alerte) si jamais définie.
    public var orangeMinutes: Int {
        get { integer(forKey: Self.orangeMinutesKey) }
        set { set(newValue, forKey: Self.orangeMinutesKey) }
    }

    /// Label personnalisé affiché au-dessus du feu tricolore. Défaut: "DeepSeek".
    public var peakLabel: String {
        get { string(forKey: Self.peakLabelKey) ?? "DeepSeek" }
        set { set(newValue, forKey: Self.peakLabelKey) }
    }

    /// Format d'heure : `true` = 24h, `false` = 12h (AM/PM). Défaut: `true`.
    public var use24Hour: Bool {
        get {
            if object(forKey: Self.use24HourKey) == nil { return true }
            return bool(forKey: Self.use24HourKey)
        }
        set { set(newValue, forKey: Self.use24HourKey) }
    }
}
