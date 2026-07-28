import Testing
import Foundation
@testable import sariel

struct DateDayKeyTests {

    @Test func sameCalendarDayProducesSameKey() {
        let calendar = Calendar.current
        var components = DateComponents(year: 2026, month: 6, day: 15, hour: 1)
        let earlyMorning = calendar.date(from: components)!

        components.hour = 23
        let lateEvening = calendar.date(from: components)!

        #expect(earlyMorning.dayKey == lateEvening.dayKey)
    }

    @Test func crossingMidnightProducesDifferentKeys() {
        let calendar = Calendar.current
        var components = DateComponents(year: 2026, month: 6, day: 15, hour: 23, minute: 59)
        let justBeforeMidnight = calendar.date(from: components)!

        components.day = 16
        components.hour = 0
        components.minute = 1
        let justAfterMidnight = calendar.date(from: components)!

        #expect(justBeforeMidnight.dayKey != justAfterMidnight.dayKey)
    }

    @Test func keyMatchesExpectedYearMonthDayFormat() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2026, month: 3, day: 5, hour: 12)
        let date = calendar.date(from: components)!

        #expect(date.dayKey == "2026-03-05")
    }
}
