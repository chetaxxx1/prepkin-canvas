import XCTest
@testable import PrepkinCanvas

/// The rating is the one number in this app that can go down, so the rules it goes
/// down by are worth walking in full.
final class RatingTests: XCTestCase {
    private let day1 = DayKey(raw: "2026-09-08")
    private let day2 = DayKey(raw: "2026-09-09")
    private let day3 = DayKey(raw: "2026-09-10")

    private func fresh(on day: DayKey) -> GameState {
        var s = GameState()
        s.currentDay = day
        s.maxDayReached = day
        return s
    }

    // MARK: - The maths

    func testAnEvenMatchIsWorthNothingEitherWay() {
        let even = PlayerRating(value: 1200, settled: 50)
        XCTAssertEqual(Rating.after(even, puzzle: 1200, solved: true, day: day1).lastDelta, 8)
        XCTAssertEqual(Rating.after(even, puzzle: 1200, solved: false, day: day1).lastDelta, -8)
    }

    func testBeatingAHardBoardPaysMoreThanBeatingAnEasyOne() {
        let me = PlayerRating(value: 1000, settled: 50)
        let hard = Rating.after(me, puzzle: 1800, solved: true, day: day1).lastDelta
        let easy = Rating.after(me, puzzle: 500, solved: true, day: day1).lastDelta
        XCTAssertGreaterThan(hard, easy)
        XCTAssertGreaterThan(hard, 0)
        XCTAssertGreaterThanOrEqual(easy, 0, "a win is never a drop")
    }

    func testLosingToAnEasyBoardCostsMoreThanLosingToAHardOne() {
        let me = PlayerRating(value: 1500, settled: 50)
        let easy = Rating.after(me, puzzle: 500, solved: false, day: day1).lastDelta
        let hard = Rating.after(me, puzzle: 1900, solved: false, day: day1).lastDelta
        XCTAssertLessThan(easy, hard)
        XCTAssertLessThan(easy, 0)
    }

    func testProvisionalMovesTwiceAsFast() {
        let new = PlayerRating(value: 800, settled: 0)
        let old = PlayerRating(value: 800, settled: Rating.provisionalResults)
        let fast = Rating.after(new, puzzle: 1200, solved: true, day: day1).lastDelta
        let slow = Rating.after(old, puzzle: 1200, solved: true, day: day1).lastDelta
        // Not exactly twice, because each is rounded to a whole point on its own.
        XCTAssertLessThanOrEqual(abs(fast - slow * 2), 1)
        XCTAssertGreaterThan(fast, slow)
        XCTAssertTrue(new.isProvisional)
        XCTAssertFalse(old.isProvisional)
        XCTAssertTrue(new.display.hasSuffix("?"))
    }

    func testAnUnratedBoardChangesNothing() {
        let me = PlayerRating(value: 1000, settled: 3, lastDelta: 9)
        let after = Rating.after(me, puzzle: Rating.unrated, solved: false, day: day1)
        XCTAssertEqual(after, me, "a fallback board must not be able to cost a rating")
    }

    func testTheRatingNeverFallsThroughTheFloor() {
        var me = PlayerRating(value: Rating.floor, settled: 50)
        for _ in 0..<40 { me = Rating.after(me, puzzle: 400, solved: false, day: day1) }
        XCTAssertEqual(me.value, Rating.floor)
    }

    // MARK: - How a game feeds it

    func testSolvingARatedBoardRaisesTheRating() {
        var s = fresh(on: day1)
        let day = day1
        s.savePlayProgress(\.balancePlay, [0, 1], day: day, puzzleRating: 1400)
        s.recordPlaySolve(\.balancePlay, reason: .balance, day: day)
        XCTAssertGreaterThan(s.rating.value, Rating.start)
        XCTAssertEqual(s.rating.settled, 1)
    }

    func testAnUnfinishedBoardIsALossOnTheNextDay() {
        var s = fresh(on: day1)
        s.savePlayProgress(\.pearlsPlay, [0, 0], day: day1, puzzleRating: 900)
        XCTAssertEqual(s.rating.settled, 0, "nothing settles on the day it was played")
        s.advance(to: day2)
        XCTAssertEqual(s.rating.settled, 1)
        XCTAssertLessThan(s.rating.value, Rating.start)
    }

    func testAnUnfinishedBoardIsOnlyEverSettledOnce() {
        var s = fresh(on: day1)
        s.savePlayProgress(\.tracePlay, [0], day: day1, puzzleRating: 900)
        s.advance(to: day2)
        let once = s.rating.value
        s.advance(to: day3)
        XCTAssertEqual(s.rating.value, once)
        XCTAssertEqual(s.rating.settled, 1)
    }

    func testABoardSolvedOnItsOwnDayIsNeverSettledAsALoss() {
        var s = fresh(on: day1)
        s.savePlayProgress(\.sortPlay, [0, 1, 2, 3], day: day1, puzzleRating: 1500)
        s.recordPlaySolve(\.sortPlay, reason: .sort, day: day1)
        let won = s.rating.value
        s.advance(to: day2)
        XCTAssertEqual(s.rating.value, won)
        XCTAssertEqual(s.rating.settled, 1)
    }

    func testOpeningAGameWithoutMovingIsNotAnAttempt() {
        var s = fresh(on: day1)
        // No `savePlayProgress`, which is what a first move calls.
        s.advance(to: day2)
        XCTAssertEqual(s.rating.settled, 0)
        XCTAssertEqual(s.rating.value, Rating.start)
    }

    func testDailyWordDoesNotTouchTheRating() {
        var s = fresh(on: day1)
        s.recordWordleWin(guesses: 3)
        XCTAssertEqual(s.rating, PlayerRating(), "luck games stay out of the rating")
    }

    // MARK: - The content

    func testEveryDealtPuzzleCarriesARating() {
        for (name, ratings) in [("balance", Catalog.balance.map(\.rating)),
                                ("pearls", Catalog.pearls.map(\.rating)),
                                ("trace", Catalog.trace.map(\.rating)),
                                ("sorts", Catalog.sorts.map(\.rating)),
                                ("weaves", Catalog.weaves.map(\.rating))] {
            XCTAssertFalse(ratings.isEmpty, "\(name) is empty")
            for r in ratings {
                XCTAssertGreaterThanOrEqual(r, 400, "\(name) has a puzzle rated below the floor")
                XCTAssertLessThanOrEqual(r, 2000, "\(name) has a puzzle rated above the ceiling")
            }
            XCTAssertGreaterThan(Set(ratings).count, 1, "\(name) rates every board the same")
        }
    }

    /// The save file has to survive a build that predates the rating.
    func testAnOldSaveDecodesToAFreshRating() throws {
        let json = Data(#"{"currentDay":"2026-09-08"}"#.utf8)
        let s = try Store.decoder.decode(GameState.self, from: json)
        XCTAssertEqual(s.rating, PlayerRating())
    }
}
