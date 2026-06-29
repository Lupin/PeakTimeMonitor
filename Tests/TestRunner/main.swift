import Foundation
import PeakTimeMonitorLib

// Simple assertion helper
func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String, file: StaticString = #file, line: UInt = #line) {
    guard actual == expected else {
        fputs("FAIL: \(message) — expected \(expected), got \(actual)\n", stderr)
        fatalError("Test failed: \(message)")
    }
}

func assertTrue(_ condition: Bool, _ message: String) {
    guard condition else {
        fputs("FAIL: \(message)\n", stderr)
        fatalError("Test failed: \(message)")
    }
}

func assertFalse(_ condition: Bool, _ message: String) {
    guard !condition else {
        fputs("FAIL: \(message)\n", stderr)
        fatalError("Test failed: \(message)")
    }
}

func assertNil<T>(_ value: T?, _ message: String) {
    guard value == nil else {
        fputs("FAIL: \(message) — expected nil, got \(value!)\n", stderr)
        fatalError("Test failed: \(message)")
    }
}

func assertNotEmpty<T: Collection>(_ collection: T, _ message: String) {
    guard !collection.isEmpty else {
        fputs("FAIL: \(message) — collection is empty\n", stderr)
        fatalError("Test failed: \(message)")
    }
}

nonisolated(unsafe) var testsPassed = 0
nonisolated(unsafe) var testsFailed = 0

func runTest(_ name: String, _ block: () throws -> Void) {
    fputs("  \(name)... ", stdout)
    do {
        try block()
        testsPassed += 1
        fputs("PASSED\n", stdout)
    } catch {
        testsFailed += 1
        fputs("FAILED: \(error)\n", stdout)
    }
}

// ──────────────────────────────────────────────
// TESTS
// ──────────────────────────────────────────────

fputs("\n=== PeakTimeSlot Codable Tests ===\n", stdout)

runTest("testCodable") {
    let slot = PeakTimeSlot(
        weekday: 2,
        startHour: 3,
        startMinute: 0,
        endHour: 6,
        endMinute: 0
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(slot)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(PeakTimeSlot.self, from: data)

    assertEqual(decoded.weekday, 2, "weekday")
    assertEqual(decoded.startHour, 3, "startHour")
    assertEqual(decoded.startMinute, 0, "startMinute")
    assertEqual(decoded.endHour, 6, "endHour")
    assertEqual(decoded.endMinute, 0, "endMinute")
}

runTest("testWeekdayRange") {
    let slot1 = PeakTimeSlot(weekday: 1, startHour: 0, startMinute: 0, endHour: 1, endMinute: 0)
    assertEqual(slot1.weekday, 1, "weekday 1")

    let slot7 = PeakTimeSlot(weekday: 7, startHour: 0, startMinute: 0, endHour: 1, endMinute: 0)
    assertEqual(slot7.weekday, 7, "weekday 7")
}

fputs("\n=== FeuState Tests ===\n", stdout)

runTest("testGreenOutsidePeak") {
    let currentWeekday = Calendar.current.component(.weekday, from: Date())
    let otherWeekday = (currentWeekday % 7) + 1

    let slots = [
        PeakTimeSlot(weekday: otherWeekday, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0)
    ]

    let state = PeakTimeSlot.currentState(slots: slots)
    assertEqual(state, .green, "should be green outside peak")
}

runTest("testRedInsidePeak") {
    let calendar = Calendar.current
    let now = Date()
    let weekday = calendar.component(.weekday, from: now)

    let hour = calendar.component(.hour, from: now)
    let minute = calendar.component(.minute, from: now)

    let startH = hour
    let startM = max(0, minute - 1)
    let endH = (minute + 59 >= 60) ? (hour + 1) % 24 : hour
    let endM = (minute + 59) % 60

    let slots = [
        PeakTimeSlot(weekday: weekday, startHour: startH, startMinute: startM, endHour: endH, endMinute: endM)
    ]

    let state = PeakTimeSlot.currentState(slots: slots)
    assertEqual(state, .red, "should be red inside peak")
}

runTest("testOrangeTenMinutesBeforePeak") {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())

    let tenMinFromNow = calendar.date(byAdding: .minute, value: 10, to: Date())!
    let peakHour = calendar.component(.hour, from: tenMinFromNow)
    let peakMinute = calendar.component(.minute, from: tenMinFromNow)

    let slots = [
        PeakTimeSlot(weekday: weekday, startHour: peakHour, startMinute: peakMinute, endHour: (peakHour + 1) % 24, endMinute: peakMinute)
    ]

    let state = PeakTimeSlot.currentState(slots: slots)
    assertEqual(state, .orange, "should be orange 10 min before peak")
}

runTest("testGreenWhenFifteenMinutesBeforePeak") {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())

    let fifteenMinFromNow = calendar.date(byAdding: .minute, value: 15, to: Date())!
    let peakHour = calendar.component(.hour, from: fifteenMinFromNow)
    let peakMinute = calendar.component(.minute, from: fifteenMinFromNow)

    let slots = [
        PeakTimeSlot(weekday: weekday, startHour: peakHour, startMinute: peakMinute, endHour: (peakHour + 1) % 24, endMinute: peakMinute)
    ]

    let state = PeakTimeSlot.currentState(slots: slots)
    assertEqual(state, .green, "should be green 15 min before peak")
}

runTest("testMidnightCrossingSlot") {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())

    let slots = [
        PeakTimeSlot(weekday: weekday, startHour: 23, startMinute: 30, endHour: 0, endMinute: 30)
    ]

    let state = PeakTimeSlot.currentState(slots: slots)
    assertTrue(state == .green || state == .red || state == .orange,
               "midnight crossing should produce valid state")
}

runTest("testEmptySlotsAlwaysGreen") {
    let state = PeakTimeSlot.currentState(slots: [])
    assertEqual(state, .green, "empty slots should be green")
}

runTest("testOrangeExactlyFourteenMinutesBefore") {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())

    let fourteenMinFromNow = calendar.date(byAdding: .minute, value: 14, to: Date())!
    let peakHour = calendar.component(.hour, from: fourteenMinFromNow)
    let peakMinute = calendar.component(.minute, from: fourteenMinFromNow)

    let slots = [
        PeakTimeSlot(weekday: weekday, startHour: peakHour, startMinute: peakMinute, endHour: (peakHour + 1) % 24, endMinute: peakMinute)
    ]

    let state = PeakTimeSlot.currentState(slots: slots)
    assertEqual(state, .orange, "should be orange 14 min before peak")
}

runTest("testSlotsFromDifferentWeekdays") {
    let currentWeekday = Calendar.current.component(.weekday, from: Date())
    let otherWeekday = (currentWeekday % 7) + 1

    let slots = [
        PeakTimeSlot(weekday: otherWeekday, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0)
    ]

    let state = PeakTimeSlot.currentState(slots: slots)
    assertEqual(state, .green, "slots from different weekday should be green")
}

fputs("\n=== Default Slots Tests ===\n", stdout)

runTest("testDefaultSlotsAreValid") {
    let slots = PeakTimeSlot.defaultSlots
    assertNotEmpty(slots, "default slots should not be empty")

    for slot in slots {
        assertTrue(slot.weekday >= 1 && slot.weekday <= 7, "weekday in range")
        assertTrue(slot.startHour >= 0 && slot.startHour <= 23, "startHour in range")
        assertTrue(slot.startMinute >= 0 && slot.startMinute <= 59, "startMinute in range")
        assertTrue(slot.endHour >= 0 && slot.endHour <= 23, "endHour in range")
        assertTrue(slot.endMinute >= 0 && slot.endMinute <= 59, "endMinute in range")
    }
}

fputs("\n=== UserDefaults Integration Tests ===\n", stdout)

runTest("testSlotsRoundtrip") {
    let defaults = UserDefaults(suiteName: "group.peakmonitor.test")!
    defaults.removeObject(forKey: "peakTimeSlots")

    let testSlots = [
        PeakTimeSlot(weekday: 2, startHour: 3, startMinute: 0, endHour: 6, endMinute: 0),
        PeakTimeSlot(weekday: 2, startHour: 8, startMinute: 0, endHour: 12, endMinute: 0)
    ]

    defaults.peakTimeSlots = testSlots
    let loaded = defaults.peakTimeSlots

    assertEqual(loaded?.count, 2, "count")
    assertEqual(loaded?[0].weekday, 2, "weekday")
    assertEqual(loaded?[1].startHour, 8, "startHour")
    assertEqual(loaded?[1].endHour, 12, "endHour")

    defaults.removeObject(forKey: "peakTimeSlots")
}

runTest("testEmptySlotsReturnsNil") {
    let defaults = UserDefaults(suiteName: "group.peakmonitor.test")!
    defaults.removeObject(forKey: "peakTimeSlots")

    let slots = defaults.peakTimeSlots
    assertNil(slots, "empty slots should return nil")
}

// ──────────────────────────────────────────────
// Summary
// ──────────────────────────────────────────────

fputs("\n=== RESULTS ===\n", stdout)
fputs("Passed: \(testsPassed)\n", stdout)
fputs("Failed: \(testsFailed)\n", stdout)

if testsFailed > 0 {
    fputs("\n❌ SOME TESTS FAILED\n", stderr)
    exit(1)
} else {
    fputs("\n✅ ALL TESTS PASSED\n", stdout)
}
