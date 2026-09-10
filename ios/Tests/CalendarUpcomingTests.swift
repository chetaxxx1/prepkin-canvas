import XCTest
@testable import PrepkinCanvas

/// The Calendar redesign's two pure pieces: the date typed into quick add, and
/// the rules that group the Upcoming list.
///
/// Every date test runs against a fixed "now" — Thursday 10 September 2026 at
/// 9:00 AM — so a test that passes today passes in December.
final class CalendarUpcomingTests: XCTestCase {

    private var cal: Calendar { .current }

    private var now: Date {
        cal.date(from: DateComponents(year: 2026, month: 9, day: 10, hour: 9))!
    }

    private func parse(_ text: String) -> DatePhrase? {
        DatePhrase.parse(text, now: now, calendar: cal)
    }

    private func day(_ text: String) -> String? { parse(text)?.day.raw }

    // MARK: - One test per phrase the brief names

    func testToday() {
        XCTAssertEqual(day("Read ch 4 today"), "2026-09-10")
        XCTAssertNil(parse("Read ch 4 today")?.minute)
    }

    func testTomorrow() {
        XCTAssertEqual(day("Lab writeup tomorrow"), "2026-09-11")
    }

    func testEveryWeekdayShortAndLong() {
        // Thursday 10 Sep. The coming one, today included, the way Todoist does it.
        let expected = ["sun": "2026-09-13", "mon": "2026-09-14", "tue": "2026-09-15",
                        "wed": "2026-09-16", "thu": "2026-09-10", "fri": "2026-09-11",
                        "sat": "2026-09-12"]
        let long = ["sun": "sunday", "mon": "monday", "tue": "tuesday", "wed": "wednesday",
                    "thu": "thursday", "fri": "friday", "sat": "saturday"]
        for (short, want) in expected {
            XCTAssertEqual(day("Quiz \(short)"), want, short)
            XCTAssertEqual(day("Quiz \(long[short]!)"), want, long[short]!)
        }
    }

    func testTypingTodaysWeekdayMeansToday() {
        XCTAssertEqual(day("Bio quiz thu"), "2026-09-10")
    }

    func testWeekdayWithATime() {
        let p = parse("Bio quiz fri 4pm")
        XCTAssertEqual(p?.day.raw, "2026-09-11")
        XCTAssertEqual(p?.minute, 16 * 60)
        XCTAssertEqual(DatePhrase.title("Bio quiz fri 4pm", without: p), "Bio quiz")
    }

    func testSlashDate() {
        XCTAssertEqual(day("Essay 9/14"), "2026-09-14")
    }

    func testNamedMonthAndDay() {
        XCTAssertEqual(day("Essay sep 14"), "2026-09-14")
        XCTAssertEqual(day("Essay sept 14"), "2026-09-14")
        XCTAssertEqual(day("Essay september 14"), "2026-09-14")
        XCTAssertEqual(day("Essay Sep. 14th"), "2026-09-14")
    }

    func testNextWeekIsTheComingMonday() {
        XCTAssertEqual(day("Start reading next week"), "2026-09-14")
    }

    // MARK: - The edges that keep it honest

    func testABareNumberIsNeverATime() {
        // "Ch. 5" must survive. Five o'clock is not what anyone meant.
        XCTAssertNil(parse("Problem set ch. 5"))
        XCTAssertNil(parse("Read pages 30 40"))
    }

    func testAStandaloneTimeMeansToday() {
        let p = parse("Essay draft 4pm")
        XCTAssertEqual(p?.day.raw, "2026-09-10")
        XCTAssertEqual(p?.minute, 16 * 60)
    }

    func testTwentyFourHourClock() {
        XCTAssertEqual(parse("Seminar 16:30")?.minute, 16 * 60 + 30)
        XCTAssertEqual(parse("Seminar fri 09:05")?.minute, 9 * 60 + 5)
    }

    func testMiddayAndMidnightDoNotWrapWrong() {
        XCTAssertEqual(parse("Deadline 12pm")?.minute, 12 * 60)
        XCTAssertEqual(parse("Deadline 12am")?.minute, 0)
    }

    func testALeadInWordIsEatenWithThePhrase() {
        let text = "Submit writing task by fri 4 pm"
        let p = parse(text)
        XCTAssertEqual(p?.day.raw, "2026-09-11")
        XCTAssertEqual(DatePhrase.title(text, without: p), "Submit writing task")
    }

    func testADateAlreadyGoneRollsToNextYear() {
        XCTAssertEqual(day("Taxes 3/1"), "2027-03-01")
    }

    func testAnImpossibleDateIsNotADate() {
        XCTAssertNil(parse("Room 13/45"))
    }

    func testTheTitleIsWhatIsLeft() {
        XCTAssertEqual(DatePhrase.title("tomorrow", without: parse("tomorrow")), "")
        XCTAssertEqual(DatePhrase.title("Bio quiz  fri  4pm  ", without: parse("Bio quiz  fri  4pm  ")),
                       "Bio quiz")
    }

    // MARK: - What the chip says

    func testTheChipSaysItBack() {
        let f = { (d: String, m: Int?) in
            DatePhrase.label(day: DayKey(raw: d), minute: m, now: self.now, calendar: self.cal)
        }
        XCTAssertEqual(f("2026-09-10", nil), "Today")
        XCTAssertEqual(f("2026-09-11", nil), "Tomorrow")
        XCTAssertEqual(f("2026-09-12", nil), "Saturday")
        XCTAssertEqual(f("2026-09-30", nil), "Sep 30")
        XCTAssertTrue(f("2026-09-11", 16 * 60).hasPrefix("Tomorrow "))
    }

    // MARK: - Grouping: only days with something on them

    private let today = DayKey(raw: "2026-09-10")

    private func week(_ from: String) -> [DayKey] {
        let start = DayKey(raw: from)
        return (0..<7).map { start.adding(days: $0, calendar: cal) }
    }

    func testEmptyDaysDoNotGetAHeader() {
        let busy: Set<String> = ["2026-09-10", "2026-09-12"]
        let blocks = Upcoming.blocks(week("2026-09-06"), today: today, dropPast: true) {
            !busy.contains($0.raw)
        }
        // Sun–Wed are gone (past, in today's week), Thu and Sat are days, and
        // the one empty day between them is a fold rather than a header.
        XCTAssertEqual(blocks.map(\.id),
                       ["2026-09-10", "fold-2026-09-11", "2026-09-12"])
    }

    func testARunOfEmptyDaysIsOneLine() {
        let blocks = Upcoming.blocks(week("2026-09-10"), today: today, dropPast: true) {
            $0.raw != "2026-09-10"
        }
        XCTAssertEqual(blocks.count, 2)
        guard case .folded(let run) = blocks[1] else { return XCTFail("expected a fold") }
        XCTAssertEqual(run.count, 6)
        XCTAssertEqual(Upcoming.foldLabel(run, calendar: cal), "Fri – Wed · free")
    }

    func testTodayNeverFoldsEvenWhenItIsEmpty() {
        let blocks = Upcoming.blocks(week("2026-09-10"), today: today, dropPast: true) { _ in true }
        XCTAssertEqual(blocks.first, .day(today))
    }

    func testAWeekEntirelyInThePastKeepsItsDays() {
        let blocks = Upcoming.blocks(week("2026-08-30"), today: today, dropPast: false) { _ in false }
        XCTAssertEqual(blocks.count, 7)
    }

    func testOneEmptyDayReadsAsOneDay() {
        XCTAssertEqual(Upcoming.foldLabel([DayKey(raw: "2026-09-13")], calendar: cal), "Sun · free")
    }

    // MARK: - Grouping: what a day header says

    func testHeadingsUseWordsNearAndMonthsFarOut() {
        let h = { Upcoming.heading(for: DayKey(raw: $0), today: self.today, calendar: self.cal) }
        XCTAssertEqual(h("2026-09-10").lead, "Today")
        XCTAssertTrue(h("2026-09-10").isToday)
        XCTAssertEqual(h("2026-09-11").lead, "Tomorrow")
        XCTAssertEqual(h("2026-09-12").lead, "Saturday")
        XCTAssertEqual(h("2026-09-23").lead, "Wednesday")
        // Past a fortnight a weekday stops helping and the month takes over.
        XCTAssertEqual(h("2026-09-24").lead, "September")
        XCTAssertEqual(h("2026-10-05").lead, "October")
        XCTAssertEqual(h("2026-09-24").date, "Sep 24")
    }

    // MARK: - Still counts

    private func task(_ id: String, done: Bool = false, locked: Bool = false) -> DailyTask {
        DailyTask(id: id, title: id, kind: .study, done: done, isLocked: locked)
    }

    func testStillCountsTakesOpenWorkOldestFirst() {
        let rows = Upcoming.stillCounts(today: today, calendar: cal) { day in
            switch day.raw {
            case "2026-09-09": return [self.task("yesterday")]
            case "2026-09-05": return [self.task("last-friday")]
            default: return []
            }
        }
        XCTAssertEqual(rows.map(\.id), ["last-friday", "yesterday"])
    }

    func testStillCountsLeavesOutWhatIsDoneOrHandedIn() {
        let rows = Upcoming.stillCounts(today: today, calendar: cal) { day in
            day.raw == "2026-09-08"
                ? [self.task("open"), self.task("done", done: true), self.task("in", locked: true)]
                : []
        }
        XCTAssertEqual(rows.map(\.id), ["open"])
    }

    func testStillCountsStopsAtAFortnight() {
        var asked: [String] = []
        _ = Upcoming.stillCounts(today: today, calendar: cal) { day in
            asked.append(day.raw)
            return []
        }
        XCTAssertEqual(asked.first, "2026-08-27")
        XCTAssertEqual(asked.last, "2026-09-09")
        XCTAssertEqual(asked.count, 14)
    }
}
