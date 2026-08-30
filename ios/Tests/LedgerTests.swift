import XCTest
@testable import PrepkinCanvas

final class LedgerTests: XCTestCase {
    private let day = DayKey(raw: "2026-08-29")

    private func earn(_ key: String, _ amount: Int, units: Int = 1, at: Date = Date()) -> CoinEntry {
        CoinEntry(key: key, amount: amount, reason: .task, units: units, day: day, at: at)
    }

    func testBalanceIsTheSumOfTheLines() {
        var l = Ledger()
        l.post(earn("a", 30))
        l.post(earn("b", 20))
        XCTAssertEqual(l.balance, 50)
        XCTAssertEqual(l.balance, l.openingBalance + l.entries.reduce(0) { $0 + $1.amount })
    }

    func testTheSameKeyOnlyPaysOnce() {
        var l = Ledger()
        XCTAssertTrue(l.post(earn("task:l-1:2026-08-29", 30)))
        XCTAssertFalse(l.post(earn("task:l-1:2026-08-29", 30)))
        XCTAssertEqual(l.balance, 30)
        XCTAssertEqual(l.entries.count, 1)
    }

    func testRevokeGivesTheCoinsBackAndFreesTheKey() {
        var l = Ledger()
        l.post(earn("t", 30))
        XCTAssertTrue(l.revoke("t"))
        XCTAssertEqual(l.balance, 0)
        XCTAssertFalse(l.isClaimed("t"))
        XCTAssertTrue(l.post(earn("t", 30)), "the key should be usable again after an undo")
    }

    func testRevokingSomethingThatIsNotThereChangesNothing() {
        var l = Ledger()
        l.post(earn("t", 30))
        XCTAssertFalse(l.revoke("nope"))
        XCTAssertEqual(l.balance, 30)
    }

    func testAPurchaseCannotOverdraw() {
        var l = Ledger()
        l.post(earn("t", 30))
        let tooMuch = CoinEntry(key: "species:ember", amount: -300, reason: .species, day: day)
        XCTAssertFalse(l.post(tooMuch))
        XCTAssertEqual(l.balance, 30)
    }

    func testBalanceSurvivesEncodingAndDecoding() throws {
        var l = Ledger(openingBalance: 15)
        l.post(earn("a", 30))
        l.post(CoinEntry(key: "scene:meadow", amount: -20, reason: .scene, day: day))
        let data = try Store.encoder.encode(l)
        let back = try Store.decoder.decode(Ledger.self, from: data)
        XCTAssertEqual(back.balance, 25, "the cached balance has to be rebuilt on decode")
        XCTAssertEqual(back.openingBalance, 15)
        XCTAssertEqual(back.entries.map(\.key), l.entries.map(\.key))
        XCTAssertEqual(back.entries.map(\.amount), l.entries.map(\.amount))
        // Times are stored to the second, so the entries are equal in every way the
        // app reads them, but not byte-identical to the originals.
    }

    func testWeeklyStatsComeFromTheLinesThemselves() {
        let now = Date()
        var l = Ledger()
        l.post(earn("t1", 30, at: now))
        l.post(earn("t2", 20, at: now))
        l.post(CoinEntry(key: "f1", amount: 25, reason: .focus, units: 25, day: day, at: now))
        l.post(CoinEntry(key: "w1", amount: 30, reason: .wordle, day: day, at: now))
        l.post(CoinEntry(key: "sp", amount: -300, reason: .species, day: day, at: now))

        let s = l.stats(inWeekOf: now)
        XCTAssertEqual(s.tasksDone, 2)
        XCTAssertEqual(s.focusMinutes, 25)
        XCTAssertEqual(s.wordleSolved, 1)
        XCTAssertEqual(s.coinsEarned, 105, "spending is not an earning")
    }

    func testLinesFromAnotherWeekAreNotCounted() {
        let now = Date()
        let lastMonth = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        var l = Ledger()
        l.post(earn("old", 30, at: lastMonth))
        l.post(earn("new", 30, at: now))
        XCTAssertEqual(l.stats(inWeekOf: now).tasksDone, 1)
    }
}
