import XCTest
@testable import PrepkinCanvas

/// The league's rules, held to the same promises the rest of the app makes:
/// spending never costs you a place, a pennant is never taken back, and the device
/// clock cannot be wound backwards to earn one twice.
final class LeagueStateTests: XCTestCase {

    private func day(_ raw: String) -> DayKey { DayKey(raw: raw) }

    /// 2026-08-31 is a Monday; 2026-09-06 the Sunday that closes the same ISO week.
    private let monday = DayKey(raw: "2026-08-31")
    private let sunday = DayKey(raw: "2026-09-06")
    private let nextMonday = DayKey(raw: "2026-09-07")

    private func state(on day: DayKey) -> GameState {
        var s = GameState()
        s.currentDay = day
        s.maxDayReached = day
        s.league.weekStart = WeekKey(day)
        return s
    }

    private func earn(_ s: inout GameState, _ amount: Int, on day: DayKey, key: String) {
        s.ledger.post(CoinEntry(key: key, amount: amount, reason: .task, day: day))
    }

    // MARK: - The week key

    func testAMondayAndTheSundayAfterItAreTheSameWeek() {
        XCTAssertEqual(WeekKey(monday), WeekKey(sunday), "the ISO week runs Monday to Sunday")
    }

    func testTheNextMondayStartsANewWeek() {
        XCTAssertNotEqual(WeekKey(sunday), WeekKey(nextMonday))
        XCTAssertTrue(WeekKey(sunday) < WeekKey(nextMonday), "weeks sort in calendar order")
    }

    func testWeekKeysSortAcrossAYearBoundary() {
        XCTAssertTrue(WeekKey(raw: "2025-W52") < WeekKey(raw: "2026-W01"))
        XCTAssertTrue(WeekKey(raw: "2026-W07") < WeekKey(raw: "2026-W37"),
                      "the week is always two digits, so a string compare is enough")
    }

    // MARK: - Points

    func testSpendingCoinsDoesNotReduceLeaguePoints() {
        var s = state(on: monday)
        earn(&s, 200, on: monday, key: "task:a")
        XCTAssertEqual(s.leaguePoints, 200)
        s.ledger.post(CoinEntry(key: "buy:ember", amount: -150, reason: .species, day: monday))
        XCTAssertEqual(s.leaguePoints, 200, "points are earned, never held")
    }

    func testCoinsFromAnotherWeekDoNotCount() {
        var s = state(on: nextMonday)
        earn(&s, 500, on: monday, key: "task:last-week")
        earn(&s, 40, on: nextMonday, key: "task:this-week")
        XCTAssertEqual(s.leaguePoints, 40)
    }

    // MARK: - Settling

    func testClearingTheBarPromotesAndBanksAPennant() {
        var s = state(on: monday)
        earn(&s, 150, on: monday, key: "task:a")
        s.advance(to: nextMonday)
        XCTAssertEqual(s.league.tier, .shallows)
        XCTAssertEqual(s.league.pennants, [.shallows])
        XCTAssertEqual(s.league.history.first?.coinsEarned, 150)
        XCTAssertTrue(s.league.history.first?.promoted == true)
    }

    func testFallingShortHoldsTheTierAndNeverDropsIt() {
        var s = state(on: monday)
        earn(&s, 149, on: monday, key: "task:a")
        s.advance(to: nextMonday)
        XCTAssertEqual(s.league.tier, .tidepool, "a quiet week never moves you down")
        XCTAssertTrue(s.league.pennants.isEmpty)
    }

    func testAWeekWithNothingInItChangesNothing() {
        var s = state(on: monday)
        s.league.tier = .reef
        s.league.pennants = [.shallows, .reef]
        s.advance(to: nextMonday)
        XCTAssertEqual(s.league.tier, .reef)
        XCTAssertEqual(s.league.pennants, [.shallows, .reef])
    }

    func testTidepoolIsNotAPennantYouGetForTurningUp() {
        let s = GameState()
        XCTAssertEqual(s.league.tier, .tidepool)
        XCTAssertTrue(s.league.pennants.isEmpty,
                      "a keepsake handed out for existing is worth nothing")
    }

    func testPennantsSurviveEveryLaterWeek() {
        var s = state(on: monday)
        earn(&s, 150, on: monday, key: "task:a")
        s.advance(to: nextMonday)                    // -> Shallows, pennant
        let quiet = DayKey(raw: "2026-09-14")
        s.advance(to: quiet)                         // earned nothing
        XCTAssertEqual(s.league.pennants, [.shallows], "a pennant is never taken back")
        XCTAssertEqual(s.league.tier, .shallows)
    }

    func testTheLadderStopsAtDeep() {
        XCTAssertNil(LeagueTier.deep.next)
        XCTAssertNil(LeagueRules.bar(for: .deep), "there is nothing above Deep to charge for")
        XCTAssertEqual(LeagueRules.settle(tier: .deep, coinsEarned: 100_000), .held)
    }

    func testOnlyOneTierIsClimbedPerWeek() {
        var s = state(on: monday)
        earn(&s, 5_000, on: monday, key: "task:huge")
        s.advance(to: nextMonday)
        XCTAssertEqual(s.league.tier, .shallows, "a week is worth one step, however big")
    }

    // MARK: - The clock

    func testWindingTheClockBackCannotSettleAWeekTwice() {
        var s = state(on: monday)
        earn(&s, 150, on: monday, key: "task:a")
        s.advance(to: nextMonday)
        XCTAssertEqual(s.league.history.count, 1)

        // Back to the week that already settled, then forward again.
        s.advance(to: monday)
        s.advance(to: nextMonday)
        XCTAssertEqual(s.league.history.count, 1, "a settled week cannot be reopened")
        XCTAssertEqual(s.league.pennants, [.shallows])
    }

    func testHistoryIsCappedSoTheSaveCannotGrowForever() {
        var s = LeagueState()
        for i in 0..<20 {
            s.settle(into: WeekKey(raw: String(format: "2026-W%02d", i + 1)), coinsEarned: 0)
        }
        XCTAssertEqual(s.history.count, LeagueState.historyKept)
    }

    // MARK: - Old saves

    func testASaveWithoutLeagueKeysStillLoads() throws {
        let json = #"{"ledger":{"openingBalance":900,"entries":[]},"owned":[{"speciesID":"slime","level":2}],"activeChibiID":"slime"}"#
        let s = try Store.decoder.decode(GameState.self, from: Data(json.utf8))
        XCTAssertEqual(s.ledger.balance, 900, "coins survive the schema change")
        XCTAssertEqual(s.league.tier, .tidepool)
        XCTAssertTrue(s.league.pennants.isEmpty)
        XCTAssertTrue(s.league.history.isEmpty)
    }

    func testLeagueStateRoundTripsThroughTheSaveFile() throws {
        var s = GameState()
        s.league.tier = .kelp
        s.league.pennants = [.shallows, .reef, .kelp]
        s.league.weekStart = WeekKey(raw: "2026-W36")
        let data = try Store.encoder.encode(s)
        let back = try Store.decoder.decode(GameState.self, from: data)
        XCTAssertEqual(back.league, s.league)
    }
}
