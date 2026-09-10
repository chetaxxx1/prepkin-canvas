import XCTest
@testable import PrepkinCanvas

/// What a friend did today, and the sentence under the whole group.
///
/// Four capped integers go over the wire and these are the rules that turn them
/// into English. They live here because every one of them is a way to accidentally
/// say something untrue about a person: a zero drawn as a zero, a stale row drawn
/// as today, or a headcount that includes people who are not in the number.
final class TodayLinesTests: XCTestCase {
    private let day = DayKey(Date(timeIntervalSince1970: 1_757_000_000))

    private func counts(tasks: Int = 0, focus: Int = 0,
                        lessons: Int = 0, games: Int = 0) -> TodayCounts {
        TodayCounts(tasks: tasks, focusMinutes: focus, lessons: lessons, games: games)
    }

    // MARK: - Reading the four numbers off the ledger

    private func ledger(_ entries: [CoinEntry]) -> Ledger {
        var l = Ledger()
        for e in entries { _ = l.post(e) }
        return l
    }

    func testTheFourNumbersComeOffTheLedger() {
        let l = ledger([
            CoinEntry(key: "task:a", amount: 30, reason: .task, day: day),
            CoinEntry(key: "task:b", amount: 30, reason: .task, day: day),
            CoinEntry(key: "focus:a", amount: 50, reason: .focus, units: 25, day: day),
            CoinEntry(key: "focus:b", amount: 40, reason: .focus, units: 20, day: day),
            CoinEntry(key: "lesson:a", amount: 20, reason: .lesson, day: day),
            CoinEntry(key: "word:a", amount: 30, reason: .wordle, day: day),
            CoinEntry(key: "pearls:a", amount: 10, reason: .pearls, day: day),
        ])
        let c = TodayCounts(ledger: l, day: day)
        XCTAssertEqual(c.tasks, 2)
        XCTAssertEqual(c.focusMinutes, 45, "focus counts minutes, not sessions")
        XCTAssertEqual(c.lessons, 1)
        XCTAssertEqual(c.games, 2, "the word and one board")
    }

    func testYesterdaysWorkIsNotTodays() {
        let yesterday = DayKey(Date(timeIntervalSince1970: 1_757_000_000 - 86_400))
        let l = ledger([
            CoinEntry(key: "task:old", amount: 30, reason: .task, day: yesterday),
            CoinEntry(key: "task:new", amount: 30, reason: .task, day: day),
        ])
        XCTAssertEqual(TodayCounts(ledger: l, day: day).tasks, 1)
    }

    /// Buying things is not doing things, and the retired games still decode.
    func testSpendingIsNotWorkAndTheGameCountCannotRunAway() {
        let l = ledger([
            // The ledger refuses a spend it cannot cover, so there has to be a
            // balance before anything can be bought.
            CoinEntry(key: "open", amount: 500, reason: .legacy, day: day),
            CoinEntry(key: "species:ember", amount: -220, reason: .species, day: day),
            CoinEntry(key: "scene:reef", amount: -200, reason: .scene, day: day),
            CoinEntry(key: "num:a", amount: 10, reason: .numberLine, day: day),
        ])
        let c = TodayCounts(ledger: l, day: day)
        XCTAssertEqual(c.tasks, 0)
        XCTAssertEqual(c.games, 0, "the number line is not one of the six daily boards")

        // Six is the whole board, and the bridge will not hold a seventh.
        let all = ledger([CoinReason.wordle, .balance, .pearls, .trace, .sort, .weave]
            .map { CoinEntry(key: "g:\($0.rawValue)", amount: 10, reason: $0, day: day) })
        XCTAssertEqual(TodayCounts(ledger: all, day: day).games, 6)
    }

    /// One pass over the ledger, and games still counted per day: playing the word
    /// every morning is seven games in a week, not one.
    func testAWeekIsFoldedPerDayRatherThanFlat() {
        let d1 = DayKey(raw: "2026-09-08"), d2 = DayKey(raw: "2026-09-09"), out = DayKey(raw: "2026-08-01")
        let l = ledger([
            CoinEntry(key: "w1", amount: 30, reason: .wordle, day: d1),
            CoinEntry(key: "w2", amount: 30, reason: .wordle, day: d2),
            CoinEntry(key: "p2", amount: 10, reason: .pearls, day: d2),
            CoinEntry(key: "t1", amount: 30, reason: .task, day: d1),
            CoinEntry(key: "f2", amount: 40, reason: .focus, units: 20, day: d2),
            CoinEntry(key: "old", amount: 30, reason: .task, day: out),
        ])
        let week = TodayCounts.week(ledger: l, days: [d1, d2])
        XCTAssertEqual(week.games, 3, "the word twice on two days, plus one board")
        XCTAssertEqual(week.tasks, 1, "the day outside the window is not in it")
        XCTAssertEqual(week.focusMinutes, 20)
    }

    func testAnEmptyDayIsEmptyAndSaysSoOutLoud() {
        XCTAssertTrue(counts().isEmpty)
        XCTAssertFalse(counts(tasks: 1).isEmpty)
    }

    // MARK: - The lines

    func testAZeroIsNeverALine() {
        XCTAssertEqual(TodayLines.lines(counts(tasks: 3)), ["Finished 3 tasks"])
        XCTAssertTrue(TodayLines.lines(counts()).isEmpty,
                      "a friend who did nothing today has no lines, not four zeros")
    }

    func testTheOrderIsFixedAndAtMostThreeShow() {
        let all = counts(tasks: 3, focus: 45, lessons: 2, games: 4)
        XCTAssertEqual(TodayLines.lines(all),
                       ["Focused 45 min", "Finished 3 tasks", "Read 2 lessons"])
        XCTAssertEqual(TodayLines.lines(all).count, 3, "games falls off the end, never sorted up")

        // Fixed order, not biggest first: sorting would turn a list into a ranking.
        XCTAssertEqual(TodayLines.lines(counts(tasks: 1, focus: 200)).first, "Focused 3h 20m")
    }

    func testPluralsAndHours() {
        XCTAssertEqual(TodayLines.lines(counts(tasks: 1)), ["Finished 1 task"])
        XCTAssertEqual(TodayLines.lines(counts(lessons: 1)), ["Read 1 lesson"])
        XCTAssertEqual(TodayLines.lines(counts(games: 1)), ["Solved 1 game"])
        XCTAssertEqual(TodayLines.lines(counts(focus: 59)), ["Focused 59 min"])
        XCTAssertEqual(TodayLines.lines(counts(focus: 60)), ["Focused 1h"])
        XCTAssertEqual(TodayLines.lines(counts(focus: 80)), ["Focused 1h 20m"])
        XCTAssertEqual(TodayLines.lines(counts(focus: 120)), ["Focused 2h"])
        XCTAssertEqual(TodayLines.lines(counts(games: 6)), ["Solved all six"])
    }

    func testNoLineNudgesOrShouts() {
        let every = [counts(tasks: 2), counts(focus: 45), counts(lessons: 1),
                     counts(games: 6), counts(tasks: 1, focus: 200, lessons: 3, games: 2)]
        for c in every {
            for line in TodayLines.lines(c) {
                XCTAssertFalse(line.contains("!"))
                XCTAssertFalse(line.lowercased().contains("only"))
                XCTAssertFalse(line.lowercased().contains("just"))
            }
        }
    }

    // MARK: - The week, together

    func testTheGroupSentenceCountsWhoIsActuallyInTheNumber() {
        // Four friends on the list, two of whom have a row this week.
        let sentence = TodayLines.weekly(mine: counts(tasks: 5, focus: 30),
                                         friends: [counts(tasks: 20, focus: 120, games: 6),
                                                   counts(tasks: 16, focus: 210, lessons: 2)])
        XCTAssertEqual(sentence, "You and 2 friends: 41 tasks, 6h focus, 6 games")
    }

    func testOneFriendIsSingular() {
        let sentence = TodayLines.weekly(mine: counts(tasks: 1),
                                         friends: [counts(tasks: 2)])
        XCTAssertEqual(sentence, "You and 1 friend: 3 tasks")
    }

    func testTheCardIsAbsentRatherThanEmpty() {
        XCTAssertNil(TodayLines.weekly(mine: counts(tasks: 4), friends: []),
                     "nobody to be together with")
        XCTAssertNil(TodayLines.weekly(mine: counts(), friends: [counts()]),
                     "a week of zeros is not a sentence")
    }

    func testTheGroupSentenceNeverCarriesACoin() {
        let sentence = TodayLines.weekly(mine: counts(tasks: 3, focus: 90, lessons: 1, games: 2),
                                         friends: [counts(tasks: 1)]) ?? ""
        XCTAssertFalse(sentence.lowercased().contains("coin"))
        XCTAssertFalse(sentence.contains("!"))
    }

    // MARK: - What the bridge sends back

    /// A row of four zeros reads as no row at all. The push skips an empty day, but
    /// a phone that saved at one minute past midnight may already have written one.
    func testARowOfZerosIsTreatedAsNoRowAtAll() {
        XCTAssertTrue(TodayCounts(tasks: 0, focusMinutes: 0, lessons: 0, games: 0).isEmpty)
        XCTAssertTrue(TodayLines.lines(counts()).isEmpty)
    }

    func testADayRowDecodesFromTheBridge() throws {
        let json = #"[{"id":"abc","day":"2026-09-10","tasks":4,"focus":75,"lessons":2,"games":3}]"#
        let rows = try JSONDecoder().decode([DayRow].self, from: Data(json.utf8))
        let r = try XCTUnwrap(rows.first)
        XCTAssertEqual(r.playerID, "abc")
        XCTAssertEqual(r.day.raw, "2026-09-10")
        XCTAssertEqual(r.counts.focusMinutes, 75)
        XCTAssertEqual(r.counts.games, 3)
    }

    /// A friend twelve hours ahead writes tomorrow's date. Their newest row at or
    /// before that is their today, or the lines sit empty all day and arrive late.
    func testAFriendAheadOfYouStillHasAToday() {
        let tomorrow = DayKey(Date(timeIntervalSince1970: 1_757_000_000 + 86_400))
        let rows = [DayRow(playerID: "a", day: day, counts: counts(tasks: 1)),
                    DayRow(playerID: "a", day: tomorrow, counts: counts(tasks: 9))]
        XCTAssertEqual(TodayLines.newest(rows, for: "a")?.tasks, 9)
        XCTAssertNil(TodayLines.newest(rows, for: "nobody"))
    }
}

/// The switch, from the phone's side.
///
/// The bridge hides the rows from friends when sharing is off, but that is not what
/// the privacy sheet promises. It says "your fish, and nothing else", and a student
/// reading that pictures nothing leaving the phone — so nothing does.
@MainActor
final class SharingTests: XCTestCase {
    private func state(sharing: Bool) -> AppState {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sharing-\(UUID().uuidString)", isDirectory: true)
        let defaults = UserDefaults(suiteName: "sharing-\(UUID().uuidString)")!
        let app = AppState(store: Store(directory: dir, defaults: defaults, debounce: 0),
                           makeClient: { _ in nil },
                           makeLeagueClient: { _ in nil },
                           makeStudyClient: { _ in nil },
                           makeFriendClient: { _ in MockFriendClient() })
        return app
    }

    func testTheSwitchStartsOffAndTheBoardStartsOn() {
        let s = GameState()
        XCTAssertFalse(s.shareToday, "a study log is not readable before anybody has seen a screen about it")
        XCTAssertTrue(s.shareBoard, "the fish and a solve time are what a code was handed over for")
    }

    func testTheSwitchSurvivesASave() throws {
        var s = GameState()
        s.shareToday = true
        s.shareBoard = false
        let back = try Store.decoder.decode(GameState.self, from: Store.encoder.encode(s))
        XCTAssertTrue(back.shareToday)
        XCTAssertFalse(back.shareBoard)
    }
}
