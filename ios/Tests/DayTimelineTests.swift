import XCTest
@testable import PrepkinCanvas

/// The day timeline's rules, off the screen: which rows a day gets and in what
/// order, and the words on the axis.
final class DayTimelineTests: XCTestCase {
    private typealias S = DayTimeline.Segment

    private func span(_ from: Int, _ to: Int? = nil) -> DayTimeline.Span {
        DayTimeline.Span(start: from, end: to)
    }

    // The handoff's Thursday: essay due 9:00, office hours 2–3, lab 3:30–5.
    private let thursday = [
        DayTimeline.Span(start: 9 * 60),
        DayTimeline.Span(start: 14 * 60, end: 15 * 60),
        DayTimeline.Span(start: 15 * 60 + 30, end: 17 * 60),
    ]

    func testADayThatIsNotTodayDrawsEveryGapAndWhatIsLeft() {
        XCTAssertEqual(DayTimeline.segments(thursday, now: nil), [
            .item(0),
            .gap(from: 9 * 60, to: 14 * 60),
            .item(1),
            .gap(from: 15 * 60, to: 15 * 60 + 30),
            .item(2),
            .rest(from: 17 * 60),
        ])
    }

    func testNowSitsAtItsTimeAndThePastGapIsNotDrawn() {
        // 10:02, after the pin. The pin is over; the wait until 2:00 starts now.
        XCTAssertEqual(DayTimeline.segments(thursday, now: 10 * 60 + 2), [
            .item(0),
            .now,
            .gap(from: 10 * 60 + 2, to: 14 * 60),
            .item(1),
            .gap(from: 15 * 60, to: 15 * 60 + 30),
            .item(2),
            .rest(from: 17 * 60),
        ])
    }

    func testNowInsideAClassRidesOnTheBlock() {
        let out = DayTimeline.segments(thursday, now: 14 * 60 + 30)
        XCTAssertEqual(out[1], .item(1, nowAt: 0.5))
        XCTAssertFalse(out.contains(.now))
    }

    func testNowAfterEverythingLeavesTheRestOfTheDayFromNow() {
        XCTAssertEqual(DayTimeline.segments(thursday, now: 18 * 60), [
            .item(0), .item(1), .item(2), .now, .rest(from: 18 * 60),
        ])
    }

    func testNowBeforeAnythingSaysHowLongUntilTheFirstThing() {
        XCTAssertEqual(DayTimeline.segments(thursday, now: 8 * 60).prefix(3), [
            .now, .gap(from: 8 * 60, to: 9 * 60), .item(0),
        ])
    }

    func testAnEmptyDayIsJustTheRest() {
        XCTAssertEqual(DayTimeline.segments([], now: nil), [.rest(from: nil)])
        XCTAssertEqual(DayTimeline.segments([], now: 600), [.now, .rest(from: 600)])
    }

    func testSpansAreOrderedByStartWhateverOrderTheyArrive() {
        let out = DayTimeline.segments([thursday[2], thursday[0], thursday[1]], now: nil)
        XCTAssertEqual(out.first, .item(1))
        XCTAssertEqual(out[2], .item(2))
        XCTAssertEqual(out[4], .item(0))
    }

    func testBackToBackClassesHaveNoGapBetweenThem() {
        let out = DayTimeline.segments([span(600, 660), span(660, 720)], now: nil)
        XCTAssertEqual(out, [.item(0), .item(1), .rest(from: 720)])
    }

    func testAnOverlapNeverMakesANegativeGap() {
        let out = DayTimeline.segments([span(600, 720), span(660, 690)], now: nil)
        XCTAssertEqual(out, [.item(0), .item(1), .rest(from: 720)])
    }

    // MARK: - Words

    func testLengthsReadLikeAPerson() {
        XCTAssertEqual(DayTimeline.length(30), "30m")
        XCTAssertEqual(DayTimeline.length(60), "1h")
        XCTAssertEqual(DayTimeline.length(90), "1h 30m")
        XCTAssertEqual(DayTimeline.length(230), "3h 50m")
    }

    func testTheClockDropsItsMeridiem() {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US")
        XCTAssertEqual(DayTimeline.clock(14 * 60, calendar: cal), "2:00")
        XCTAssertEqual(DayTimeline.clock(9 * 60 + 5, calendar: cal), "9:05")
    }

    func testAnOffHourLabelIsTheClockAndAnOnHourLabelIsTheHour() {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US")
        XCTAssertEqual(DayTimeline.hourLabel(15 * 60 + 30, calendar: cal), "3:30")
        XCTAssertFalse(DayTimeline.hourLabel(9 * 60, calendar: cal).contains(":"))
    }
}
