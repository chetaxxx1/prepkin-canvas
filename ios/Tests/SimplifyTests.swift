import XCTest
@testable import PrepkinCanvas

/// The 2026-09-12 subtraction pass, as rules: one place for each fact. Each test
/// names the screen the rule was copied from (`design/screenshots/app-simplify-
/// 2026-09-12/README.md` has the table).
final class SimplifyTests: XCTestCase {

    // MARK: - Focus (Forest's timer: one control, one button)

    /// The chip row is the three free lengths, for everybody. It used to carry 60
    /// and 90 as well, in coral, with a typed-length link under it.
    func testFocusChipRowIsExactlyTheThreeFreeLengths() {
        XCTAssertEqual(FocusView.chipLengths, [15, 25, 45])
        XCTAssertEqual(FocusView.chipLengths, FocusView.freeLengths,
                       "the chip row and the free set are one list")
    }

    /// Behind More: sixty, ninety and a typed length, in that order, all Plus.
    func testFocusMoreSheetHoldsSixtyNinetyAndTyped() {
        XCTAssertEqual(FocusView.moreItems, [.minutes(60), .minutes(90), .typed])
    }

    /// Nothing on the More sheet repeats a chip.
    func testFocusMoreSheetNeverRepeatsAChip() {
        for item in FocusView.moreItems {
            if case .minutes(let m) = item {
                XCTAssertFalse(FocusView.chipLengths.contains(m), "\(m) is already a chip")
            }
        }
    }

    // MARK: - Kin (Finch's home: one bubble on the bird, one plate under it)

    /// The name, the stars and the friendship word are one line. They used to be
    /// two pills under the bubble.
    func testKinPlateIsOneLine() {
        XCTAssertEqual(KinPlate.text(name: "Moss", level: 3, stage: .buddies), "Moss · ★★★ · Buddies")
        XCTAssertEqual(KinPlate.text(name: "Moss", level: 1, stage: .justMet), "Moss · ★☆☆ · Just met")
    }

    /// Two separators, so the three facts read as three and never run together.
    func testKinPlateHasExactlyThreeParts() {
        for level in 1...3 {
            let parts = KinPlate.text(name: "Ember", level: level, stage: .tankmates).components(separatedBy: " · ")
            XCTAssertEqual(parts.count, 3)
            XCTAssertEqual(parts[1].count, 3, "three stars, filled or not")
        }
    }

    // MARK: - Friends (Duolingo's league tab: one entry that is the league)

    /// One row opens the league. The pod row that also opened it is gone; Join
    /// lives inside the ladder screen.
    func testFriendsHasOneLeagueRow() {
        XCTAssertEqual(FriendsView.links.filter(\.opensLeague).count, 1)
        XCTAssertEqual(FriendsView.links, [.ladder, .privacy])
    }

    /// The code hint says which characters are missing from the alphabet and
    /// stops there. It used to guess a swap on the same line.
    func testCodeHintSaysOneThing() {
        XCTAssertEqual(FriendsView.badCharLine, "Codes skip I, O, 0 and 1.")
        XCTAssertFalse(FriendsView.badCharLine.contains("Try"))
        for c in "IO01" { XCTAssertFalse(PairingCode.alphabet.contains(c), "\(c) is in the alphabet after all") }
    }

    // MARK: - Calendar (Google Calendar's schedule: one line, then the next thing)

    private let cal = Calendar(identifier: .gregorian)
    private func week(_ from: String) -> [DayKey] {
        (0..<7).map { DayKey(raw: from).adding(days: $0, calendar: cal) }
    }

    /// A week with nothing on it renders one line: today's. No fold under it.
    func testEmptyWeekIsOneLine() {
        let today = DayKey(raw: "2026-09-10")
        let blocks = Upcoming.blocks(week("2026-09-06"), today: today, dropPast: true) { _ in true }
        XCTAssertEqual(blocks, [.day(today)])
    }

    /// A week with something on it still folds its empty days.
    func testABusyWeekStillFoldsItsEmptyDays() {
        let today = DayKey(raw: "2026-09-10")
        let blocks = Upcoming.blocks(week("2026-09-06"), today: today, dropPast: true) { $0.raw != "2026-09-12" }
        XCTAssertEqual(blocks.map(\.id), ["2026-09-10", "fold-2026-09-11", "2026-09-12"])
    }

    /// The next dated thing shows even three weeks out; nothing shows when nothing is.
    func testNextDatedThingIsFoundHoweverFarOut() {
        let last = DayKey(raw: "2026-09-19")
        let far = DayKey(raw: "2026-10-10")
        XCTAssertEqual(Upcoming.nextDated(after: last, calendar: cal) { $0 != far }, far)
        XCTAssertNil(Upcoming.nextDated(after: last, calendar: cal) { _ in true })
        XCTAssertNil(Upcoming.nextDated(after: last, horizon: 10, calendar: cal) { $0 != far },
                     "past the horizon is nothing, not a scan to the end of time")
    }

    // MARK: - Play (NYT Games' home: a title and tiles, no counters above them)

    /// The switch says the half's name and nothing about what is open. The dot
    /// that used to sit on the other half spoke through this label.
    func testPlaySwitchHasNoDot() {
        for h in LearnView.Half.allCases {
            XCTAssertEqual(LearnView.segmentLabel(h), h.label)
            XCTAssertFalse(LearnView.segmentLabel(h).contains("open"))
        }
    }

    /// Coins are paid, in the app's own word.
    func testPlayLineSaysPaid() {
        XCTAssertEqual(LearnView.playLine(claimed: false, total: 6, left: 6), "Six today. First finish pays 30.")
        XCTAssertEqual(LearnView.playLine(claimed: true, total: 6, left: 2), "Paid. Two more for the result line.")
        XCTAssertEqual(LearnView.playLine(claimed: true, total: 6, left: 0), "All done today. New ones tomorrow.")
        for line in [LearnView.playLine(claimed: false, total: 6, left: 6),
                     LearnView.playLine(claimed: true, total: 6, left: 2)] {
            XCTAssertFalse(line.lowercased().contains("bank"), line)
        }
    }

    /// The rating chip's one-line explainer, in Chess.com's terms.
    func testRatingExplainerIsOneLine() {
        XCTAssertEqual(LearnView.ratingExplainer,
                       "Goes up when you solve a hard one, down when you miss an easy one. Chess.com's puzzle rating, for puzzles.")
    }
}
