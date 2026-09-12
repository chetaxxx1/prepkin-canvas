import XCTest
@testable import PrepkinCanvas

/// The widget's one line, from the table in the 2026-09-09 plan. Every row, at
/// 9 AM, 3 PM and 9 PM: the time of day changes nothing except the due window.
final class WidgetLineTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 9; c.day = day; c.hour = hour; c.minute = minute
        return calendar.date(from: c)!
    }

    private let hours = [9, 15, 21]

    private func snap(tasks: [WidgetSnapshot.Task], on day: Int = 9, lastOpened: Date? = nil,
                      shiftEndsAt: Date? = nil) -> WidgetSnapshot {
        WidgetSnapshot(speciesID: "slime", stage: 2, costumeID: "none", name: "Moss",
                       kinAsset: "sprout-mint-2", plainAsset: "sprout-mint-2", coins: 120,
                       tasks: tasks, allDone: !tasks.isEmpty && tasks.allSatisfy(\.done),
                       lastOpenedAt: lastOpened ?? at(day, 8), shiftEndsAt: shiftEndsAt,
                       checkInHour: 19, dayBankSeed: 4, day: "2026-09-\(String(format: "%02d", day))",
                       writtenAt: at(day, 8))
    }

    private func task(_ id: String, _ title: String, due: Date? = nil, done: Bool = false,
                      daily: Bool = true) -> WidgetSnapshot.Task {
        WidgetSnapshot.Task(id: id, title: title, dueAt: due, done: done, isDaily: daily)
    }

    private func lines(_ s: WidgetSnapshot, day: Int = 9) -> [String] {
        hours.map { WidgetLine.line(for: s, now: at(day, $0), calendar: calendar) }
    }

    // MARK: - The table

    func testSomethingDueInTheNextThreeHoursLeads() {
        let s = snap(tasks: [task("q", "Bio quiz", due: at(9, 20), daily: false),
                             task("e", "Essay outline")])
        let eight = at(9, 20).formatted(.dateTime.hour().minute())
        XCTAssertEqual(WidgetLine.line(for: s, now: at(9, 17, 30), calendar: calendar), "Bio quiz due \(eight).")
        XCTAssertEqual(WidgetLine.line(for: s, now: at(9, 9), calendar: calendar), "2 things today. Bio quiz first.",
                       "eleven hours out is not soon")
        XCTAssertEqual(WidgetLine.line(for: s, now: at(9, 21), calendar: calendar), "2 things today. Bio quiz first.",
                       "past due is still open work, and no longer a clock")
    }

    func testMorningWithThingsOpen() {
        let s = snap(tasks: [task("q", "Bio quiz", daily: false), task("e", "Essay outline"), task("w", "10 minute walk")])
        for line in lines(s) { XCTAssertEqual(line, "3 things today. Bio quiz first.") }
    }

    func testAfternoonWithSomeDone() {
        let s = snap(tasks: [task("q", "Bio quiz", done: true, daily: false),
                             task("e", "Essay outline"), task("w", "10 minute walk")])
        for line in lines(s) { XCTAssertEqual(line, "2 left. Essay outline, then done.") }
    }

    func testAllDone() {
        let s = snap(tasks: [task("q", "Bio quiz", done: true), task("e", "Essay outline", done: true)])
        for line in lines(s) { XCTAssertEqual(line, "All done. Moss noticed.") }
    }

    func testNothingOnTheListReadsFromTheDayBank() {
        let s = snap(tasks: [])
        let bank = DayBank.line(name: "Moss", on: at(9, 12), seed: 4, calendar: calendar)
        for line in lines(s) { XCTAssertEqual(line, bank) }
        XCTAssertTrue(DayBank.lines.contains(bank.replacingOccurrences(of: "Moss", with: "Moss")))
    }

    func testNotOpenedInThreeDays() {
        let s = snap(tasks: [task("e", "Essay outline")], on: 6, lastOpened: at(6, 8))
        for line in lines(s) { XCTAssertEqual(line, "Moss is still here.") }
        // Two days is not away yet: the dailies are back, the rest is unknowable.
        XCTAssertEqual(WidgetLine.line(for: s, now: at(8, 9), calendar: calendar), "1 thing today. Essay outline first.")
    }

    func testShiftRunning() {
        let s = snap(tasks: [task("e", "Essay outline")], shiftEndsAt: at(9, 23))
        for line in lines(s) { XCTAssertEqual(line, "On shift") }
        XCTAssertEqual(WidgetLine.line(for: s, now: at(9, 23, 30), calendar: calendar),
                       "1 thing today. Essay outline first.", "a shift that ended is not a shift")
    }

    // MARK: - The day after

    func testYesterdaysSnapshotBringsTheDailiesBackAndDropsTheRest() {
        let s = snap(tasks: [task("q", "Bio quiz", due: at(12, 20), done: false, daily: false),
                             task("o", "Once", done: true, daily: false),
                             task("w", "10 minute walk", done: true)], on: 9)
        let today = WidgetLine.today(s, now: at(10, 9), calendar: calendar)
        XCTAssertEqual(today.map(\.id), ["q", "w"])
        XCTAssertFalse(today[1].done)
        XCTAssertEqual(WidgetLine.line(for: s, now: at(10, 9), calendar: calendar), "2 things today. Bio quiz first.")
    }

    // MARK: - The day bank

    func testTheDayBankHoldsItsLineAllDayAndChangesTomorrow() {
        let morning = DayBank.line(name: "Moss", on: at(9, 7), seed: 11, calendar: calendar)
        let night = DayBank.line(name: "Moss", on: at(9, 23, 59), seed: 11, calendar: calendar)
        let tomorrow = DayBank.line(name: "Moss", on: at(10, 7), seed: 11, calendar: calendar)
        XCTAssertEqual(morning, night)
        XCTAssertNotEqual(morning, tomorrow)
    }

    func testTheDayBankIsThirtyLinesWithTheKinsName() {
        XCTAssertEqual(DayBank.lines.count, 30)
        let line = DayBank.line(name: "Pebble", on: at(9, 7), seed: 0, calendar: calendar)
        XCTAssertFalse(line.contains("Moss"))
        // Every seed lands on a different opening line for the same day.
        let all = Set((0..<30).map { DayBank.line(name: "Moss", on: at(9, 7), seed: $0, calendar: calendar) })
        XCTAssertEqual(all.count, 30)
    }

    // MARK: - Under 40, no scolding

    func testEveryLineIsUnderFortyCharacters() {
        let longName = "Bartholomew"
        var lines: [String] = (0..<30).map { DayBank.line(name: longName, on: at(9, 7), seed: $0, calendar: calendar) }
            + DayBank.lines
        let longTitle = "Redo one question you got wrong from the problem set"
        let cases: [WidgetSnapshot] = [
            snap(tasks: [task("a", longTitle, due: at(9, 11), daily: false), task("b", longTitle)]),
            snap(tasks: [task("a", longTitle), task("b", longTitle), task("c", longTitle)]),
            snap(tasks: [task("a", longTitle, done: true), task("b", longTitle)]),
            snap(tasks: [task("a", longTitle, done: true)]),
            snap(tasks: []),
            snap(tasks: [task("a", longTitle)], on: 1, lastOpened: at(1, 8)),
            snap(tasks: [task("a", longTitle)], shiftEndsAt: at(9, 23)),
        ]
        for var s in cases {
            s.name = longName
            for h in hours {
                let now = at(9, h)
                lines.append(WidgetLine.line(for: s, now: now, calendar: calendar))
                lines.append(WidgetLine.count(for: s, now: now, calendar: calendar))
                lines.append(WidgetLine.stamp(s.name, now))
                lines.append("Tap a box to finish it · 12 left")
            }
        }
        let banned = ["streak", "missed", "lose", "!", "day count", "days"]
        for line in lines {
            XCTAssertLessThan(line.count, WidgetLine.maxLength, line)
            for bad in banned {
                XCTAssertFalse(line.lowercased().contains(bad), "\(line) says \(bad)")
            }
        }
    }

    // MARK: - The medium's boxes

    /// A tapped box leaves a mark; the widget draws that row done and counts it
    /// before the app has paid anything. The coins do not move until it does.
    func testATappedBoxTicksTheRowAndTheLineBeforeTheAppPays() {
        let s = snap(tasks: [task("q", "Bio quiz", daily: false), task("e", "Essay outline"), task("w", "10 minute walk")])
        let ticked = s.applying([DoneMark(taskID: "q", at: at(9, 10))])
        XCTAssertEqual(ticked.tasks.map(\.done), [true, false, false])
        XCTAssertEqual(ticked.coins, s.coins)
        XCTAssertEqual(WidgetLine.line(for: ticked, now: at(9, 15), calendar: calendar), "2 left. Essay outline, then done.")
        XCTAssertEqual(s.applying([]), s)
        let all = s.applying(["q", "e", "w"].map { DoneMark(taskID: $0, at: at(9, 10)) })
        XCTAssertTrue(all.allDone)
    }

    func testTheRowsKeepListOrderAndPreferOpenWork() {
        let three = snap(tasks: [task("a", "A", done: true), task("b", "B"), task("c", "C")])
        XCTAssertEqual(WidgetLine.rows(for: three, now: at(9, 9), calendar: calendar).map(\.id), ["a", "b", "c"])
        let five = snap(tasks: [task("a", "A", done: true), task("b", "B", done: true), task("c", "C"),
                                task("d", "D"), task("e", "E")])
        XCTAssertEqual(WidgetLine.rows(for: five, now: at(9, 9), calendar: calendar).map(\.id), ["c", "d", "e"])
    }

    func testTheTimelineHasTheFiveMoments() {
        let s = snap(tasks: [task("q", "Bio quiz", due: at(9, 20), daily: false)], shiftEndsAt: at(9, 10))
        let dates = WidgetLine.timelineDates(for: s, now: at(9, 9), calendar: calendar)
        XCTAssertEqual(dates, [at(9, 9), at(9, 10), at(9, 12), at(9, 17), at(9, 19), at(9, 20), at(10, 0)])
    }
}
