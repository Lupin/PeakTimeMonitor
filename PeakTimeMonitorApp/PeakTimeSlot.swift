import Foundation

/// Represents a peak time slot for a specific weekday.
/// weekday: 0 = all weekdays (Mon-Fri), 1 = Sunday, 2 = Monday, ..., 7 = Saturday
public struct PeakTimeSlot: Codable, Equatable, Sendable {
    public var weekday: Int       // 0-7 (0 = all weekdays)
    public var startHour: Int     // 0-23
    public var startMinute: Int   // 0-59
    public var endHour: Int       // 0-23
    public var endMinute: Int     // 0-59

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
    /// DeepSeek Paris peak times: 3h-6h and 8h-12h, Monday-Friday
    /// Uses weekday=0 (all weekdays) so it's just 2 slots instead of 10
    static let defaultSlots: [PeakTimeSlot] = [
        PeakTimeSlot(weekday: 0, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0),
        PeakTimeSlot(weekday: 0, startHour: 8, startMinute: 0, endHour: 12, endMinute: 0)
    ]

    /// Determine the current traffic-light state based on the given slots.
    /// - Parameters:
    ///   - slots: The list of peak time slots to evaluate against
    ///   - orangeMinutes: How many minutes before a peak to show orange (default 15)
    /// - Returns: `.green` if no peak is active or imminent, `.orange` if a peak starts within orangeMinutes, `.red` if currently in a peak
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
    private static let peakTimeSlotsKey = "peakTimeSlots"
    private static let orangeMinutesKey = "orangeMinutes"

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

    public var orangeMinutes: Int {
        get { integer(forKey: Self.orangeMinutesKey) }
        set { set(newValue, forKey: Self.orangeMinutesKey) }
    }
}
