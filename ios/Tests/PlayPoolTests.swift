import XCTest
@testable import PrepkinCanvas

/// The one daily Play pool: the first game finished banks 30, the rest post a zero
/// line so they still count as played. Tomorrow the pool opens again.
final class PlayPoolTests: XCTestCase {
    private let day1 = DayKey(raw: "2026-09-08")
    private let day2 = DayKey(raw: "2026-09-09")
    private let day3 = DayKey(raw: "2026-09-10")

    private func fresh(on day: DayKey) -> GameState {
        var s = GameState()
        s.currentDay = day
        s.maxDayReached = day
        return s
    }

    func testOnlyTheFirstGameOfTheDayPays() {
        var s = fresh(on: day1)
        XCTAssertNil(s.playBanked(on: day1))
        XCTAssertEqual(s.recordPlaySolve(\.ladderPlay, reason: .ladder), 30)
        XCTAssertEqual(s.playBanked(on: day1), .ladder)
        XCTAssertTrue(s.playClaimedToday)

        XCTAssertEqual(s.recordWordleWin(), 0, "the word still counts, but the pool is spent")
        XCTAssertTrue(s.wordleClaimedToday, "played today, even at zero coins")
        XCTAssertEqual(s.wordleSolved, 1)
        XCTAssertEqual(s.recordNumberLineRound(accuracy: 80), 0)
        XCTAssertTrue(s.numberLineClaimedToday)
        XCTAssertEqual(s.recordPlaySolve(\.pearlsPlay, reason: .pearls), 0)
        XCTAssertEqual(s.pearlsPlay.solved, 1)

        XCTAssertEqual(s.ledger.balance, 30, "six games are still one pool")
    }

    func testThePoolOpensAgainTomorrow() {
        var s = fresh(on: day1)
        s.recordPlaySolve(\.balancePlay, reason: .balance)
        s.advance(to: day2)
        XCTAssertFalse(s.playClaimedToday)
        XCTAssertEqual(s.recordPlaySolve(\.threadPlay, reason: .thread), 30)
        XCTAssertEqual(s.ledger.balance, 60)
    }

    /// The only counter is solves, and it only goes up. Nothing to break.
    func testASolveCountsOncePerDay() {
        var s = fresh(on: day1)
        XCTAssertEqual(s.recordPlaySolve(\.pearlsPlay, reason: .pearls), 30)
        XCTAssertEqual(s.recordPlaySolve(\.pearlsPlay, reason: .pearls), 0, "same board, same day")
        XCTAssertEqual(s.pearlsPlay.solved, 1)
        s.advance(to: day2)
        s.recordPlaySolve(\.pearlsPlay, reason: .pearls)
        XCTAssertEqual(s.pearlsPlay.solved, 2)
        s.advance(to: DayKey(raw: "2026-09-12"))
        s.recordPlaySolve(\.pearlsPlay, reason: .pearls)
        XCTAssertEqual(s.pearlsPlay.solved, 3, "a missed day costs nothing")
    }

    /// Midnight passed with the board open: the solve pays under the day it was
    /// dealt, and today's pool is still open.
    func testASolveSettlesTheDayItWasDealt() {
        var s = fresh(on: day1)
        s.advance(to: day2)
        XCTAssertEqual(s.recordPlaySolve(\.ladderPlay, reason: .ladder, day: day1), 30)
        XCTAssertFalse(s.playClaimedToday)
        XCTAssertEqual(s.recordPlaySolve(\.ladderPlay, reason: .ladder, day: day2), 30)
        XCTAssertEqual(s.ladderPlay.solved, 2)
    }

    func testProgressIsGoodOnlyForTheDayItWasDealt() {
        var s = fresh(on: day1)
        s.savePlayProgress(\.balancePlay, [0, 1, -1, -1], day: day1)
        XCTAssertEqual(s.playProgress(\.balancePlay, for: day1), [0, 1, -1, -1])
        XCTAssertNil(s.playProgress(\.balancePlay, for: day2))
        s.savePlayProgress(\.ladderPlay, ["BLANK", "BLAND"], day: day1)
        XCTAssertEqual(s.playProgress(\.ladderPlay, for: day1), ["BLANK", "BLAND"])
    }

    func testTheRecordsSurviveASaveAndLoad() throws {
        var s = fresh(on: day1)
        s.recordPlaySolve(\.threadPlay, reason: .thread)
        s.savePlayProgress(\.pearlsPlay, [0, 0, 2, 1], day: day1)
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back.threadPlay, s.threadPlay)
        XCTAssertEqual(back.pearlsPlay, s.pearlsPlay)
        XCTAssertEqual(back.playBanked(on: day1), .thread)
    }

    /// A save from before the pool existed decodes with empty records.
    func testAnOldSaveOpensWithEmptyRecords() throws {
        let s = fresh(on: day1)
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as! [String: Any]
        for k in ["ladderPlay", "threadPlay", "balancePlay", "pearlsPlay"] { json.removeValue(forKey: k) }
        let back = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(back.ladderPlay, PlayRecord<[String]>())
        XCTAssertEqual(back.pearlsPlay.solved, 0)
    }
}
