import WidgetKit
import SwiftUI
import PeakTimeMonitorLib

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

        // Refresh every 5 minutes
        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: 5,
            to: Date()
        ) ?? Date().addingTimeInterval(300)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentFeuState() -> FeuState {
        let defaults = UserDefaults(suiteName: "group.peakmonitor")
        let slots = defaults?.peakTimeSlots ?? PeakTimeSlot.defaultSlots
        return PeakTimeSlot.currentState(slots: slots)
    }
}

// MARK: - Widget View

struct PeakTimeWidgetEntryView: View {
    var entry: PeakTimeProvider.Entry

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            // Mini traffic light — three small circles
            VStack(spacing: 6) {
                Circle()
                    .fill(entry.state == .red ? Color.red : Color.gray.opacity(0.2))
                    .frame(width: 20, height: 20)
                Circle()
                    .fill(entry.state == .orange ? Color.orange : Color.gray.opacity(0.2))
                    .frame(width: 20, height: 20)
                Circle()
                    .fill(entry.state == .green ? Color.green : Color.gray.opacity(0.2))
                    .frame(width: 20, height: 20)
            }

            Spacer()

            // Status label
            Text(entry.state.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(statusColor)
                .padding(.bottom, 8)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var statusColor: Color {
        switch entry.state {
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        }
    }
}

// MARK: - Widget Configuration

struct PeakTimeWidget: Widget {
    let kind: String = "PeakTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: PeakTimeProvider()
        ) { entry in
            PeakTimeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Peak Time Monitor")
        .description("Mini feu tricolore indiquant l'état des heures de pointe.")
        .supportedFamilies([.systemSmall])
    }
}
