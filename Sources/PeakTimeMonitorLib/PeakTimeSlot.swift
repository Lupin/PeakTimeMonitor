import Foundation

/// Represents a peak time slot for a specific weekday.
/// weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday (Calendar.Component.weekday convention)
public struct PeakTimeSlot: Codable, Equatable, Sendable {
    public let weekday: Int       // 1-7
    public let startHour: Int     // 0-23
    public let startMinute: Int   // 0-59
    public let endHour: Int       // 0-23
    public let endMinute: Int     // 0-59

    public init(weekday: Int, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        self.weekday = weekday
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }
}

/// Traffic-light state for peak time monitoring
public enum FeuState: String, Equatable {
    case green  // off-peak
    case orange // peak starts in < 15 minutes
    case red    // peak is active
}

public extension PeakTimeSlot {
    /// Paris peak times from COCKPIT: 3h-6h and 8h-12h Paris time
    static let defaultSlots: [PeakTimeSlot] = [
        PeakTimeSlot(weekday: 2, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0),   // Monday 3-6
        PeakTimeSlot(weekday: 2, startHour: 8, startMinute: 0, endHour: 12, endMinute: 0),  // Monday 8-12
        PeakTimeSlot(weekday: 3, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0),   // Tuesday 3-6
        PeakTimeSlot(weekday: 3, startHour: 8, startMinute: 0, endHour: 12, endMinute: 0),  // Tuesday 8-12
        PeakTimeSlot(weekday: 4, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0),   // Wednesday 3-6
        PeakTimeSlot(weekday: 4, startHour: 8, startMinute: 0, endHour: 12, endMinute: 0),  // Wednesday 8-12
        PeakTimeSlot(weekday: 5, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0),   // Thursday 3-6
        PeakTimeSlot(weekday: 5, startHour: 8, startMinute: 0, endHour: 12, endMinute: 0),  // Thursday 8-12
        PeakTimeSlot(weekday: 6, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0),   // Friday 3-6
        PeakTimeSlot(weekday: 6, startHour: 8, startMinute: 0, endHour: 12, endMinute: 0)   // Friday 8-12
    ]

    /// Determine the current traffic-light state based on the given slots.
    /// - Parameter slots: The list of peak time slots to evaluate against
    /// - Returns: `.green` if no peak is active or imminent, `.orange` if a peak starts in < 15 minutes, `.red` if currently in a peak
    static func currentState(slots: [PeakTimeSlot]) -> FeuState {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute

        // Filter slots for today's weekday
        let todaySlots = slots.filter { $0.weekday == weekday }

        // Check if we're inside an active peak
        for slot in todaySlots {
            let startMinutes = slot.startHour * 60 + slot.startMinute
            let endMinutes = slot.endHour * 60 + slot.endMinute
            if currentMinutes >= startMinutes && currentMinutes < endMinutes {
                return .red
            }
        }

        // Check if a peak starts within 15 minutes
        for slot in todaySlots {
            let startMinutes = slot.startHour * 60 + slot.startMinute
            let diff = startMinutes - currentMinutes
            if diff > 0 && diff <= 15 {
                return .orange
            }
        }

        return .green
    }
}

// MARK: - UserDefaults Integration

extension UserDefaults {
    private static let peakTimeSlotsKey = "peakTimeSlots"

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
}
