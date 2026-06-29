import WidgetKit
import SwiftUI

// MARK: - Self-contained Model (no external dependencies)

enum FeuState: String {
    case green, orange, red
}

struct PeakTimeSlot: Codable, Equatable {
    var weekday: Int
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int

    init(weekday: Int, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        self.weekday = weekday
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }

    static let defaultSlots: [PeakTimeSlot] = {
        let days = [2, 3, 4, 5, 6] // Mon-Fri
        return days.flatMap { day in
            [
                PeakTimeSlot(weekday: day, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0),
                PeakTimeSlot(weekday: day, startHour: 8, startMinute: 0, endHour: 12, endMinute: 0)
            ]
        }
    }()

    static func currentState(slots: [PeakTimeSlot], orangeMinutes: Int = 15) -> FeuState {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        for slot in slots where slot.weekday == weekday || (slot.weekday == 0 && weekday >= 2 && weekday <= 6) {
            let start = slot.startHour * 60 + slot.startMinute
            let end = slot.endHour * 60 + slot.endMinute
            if currentMinutes >= start && currentMinutes < end { return .red }
        }
        for slot in slots where slot.weekday == weekday || (slot.weekday == 0 && weekday >= 2 && weekday <= 6) {
            let diff = (slot.startHour * 60 + slot.startMinute) - currentMinutes
            if diff > 0 && diff <= orangeMinutes { return .orange }
        }
        return .green
    }
}

// MARK: - UserDefaults Helper

extension UserDefaults {
    private static let key = "peakTimeSlots"

    var peakTimeSlots: [PeakTimeSlot]? {
        get {
            guard let data = data(forKey: Self.key) else { return nil }
            return try? JSONDecoder().decode([PeakTimeSlot].self, from: data)
        }
        set {
            if let v = newValue, let data = try? JSONEncoder().encode(v) {
                set(data, forKey: Self.key)
            } else {
                removeObject(forKey: Self.key)
            }
        }
    }
}

// MARK: - Timeline Entry

struct PeakTimeEntry: TimelineEntry {
    let date: Date
    let state: FeuState
}

// MARK: - Provider

struct PeakTimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PeakTimeEntry {
        PeakTimeEntry(date: Date(), state: .green)
    }

    func getSnapshot(in context: Context, completion: @escaping (PeakTimeEntry) -> Void) {
        let state = currentFeuState()
        completion(PeakTimeEntry(date: Date(), state: state))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PeakTimeEntry>) -> Void) {
        let state = currentFeuState()
        let entry = PeakTimeEntry(date: Date(), state: state)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentFeuState() -> FeuState {
        let defaults = UserDefaults(suiteName: "group.peakmonitor")
        let slots = defaults?.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        let orangeMin = defaults?.integer(forKey: "orangeMinutes") ?? 15
        return PeakTimeSlot.currentState(slots: slots, orangeMinutes: orangeMin > 0 ? orangeMin : 15)
    }
}

// MARK: - Widget View

struct PeakTimeWidgetEntryView: View {
    var entry: PeakTimeProvider.Entry

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            VStack(spacing: 6) {
                Circle().fill(entry.state == .red ? Color.red : Color.gray.opacity(0.2)).frame(width: 20, height: 20)
                Circle().fill(entry.state == .orange ? Color.orange : Color.gray.opacity(0.2)).frame(width: 20, height: 20)
                Circle().fill(entry.state == .green ? Color.green : Color.gray.opacity(0.2)).frame(width: 20, height: 20)
            }
            Spacer()
            Text(entry.state.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(entry.state == .red ? .red : entry.state == .orange ? .orange : .green)
                .padding(.bottom, 8)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct PeakTimeWidget: Widget {
    let kind: String = "PeakTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PeakTimeProvider()) { entry in
            PeakTimeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Peak Time Monitor")
        .description("Mini feu tricolore indiquant l'état des heures de pointe.")
        .supportedFamilies([.systemSmall])
    }
}
