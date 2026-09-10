import XCTest
@testable import PrepkinCanvas

/// The two grid games, driven through their models: taps cycle, conflicts show,
/// the solve is recognised, and a saved board comes back as it was.
@MainActor
final class PlayGameTests: XCTestCase {
    private let monday = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 7))!
    private let sunday = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 13))!

    // MARK: - Pearls

    func testPearlsDealsSevenOnWeekdaysAndEightOnSunday() {
        XCTAssertEqual(PearlsGame(date: monday).n, 7)
        XCTAssertEqual(PearlsGame(date: sunday).n, 8)
        XCTAssertEqual(PearlsGame(date: monday).puzzle, PearlsGame(date: monday).puzzle, "same day, same board")
    }

    func testPearlsTapCyclesAndStartsTheClock() {
        let g = PearlsGame(date: monday)
        XCTAssertNil(g.startedAt)
        g.tap(0); XCTAssertEqual(g.mark(0), .cross)
        XCTAssertNotNil(g.startedAt, "the stopwatch starts on the first tap")
        g.tap(0); XCTAssertEqual(g.mark(0), .pearl)
        g.tap(0); XCTAssertEqual(g.mark(0), .blank)
    }

    func testPearlsFlagsTouchingAndSharedLines() {
        let g = PearlsGame(date: monday)
        let n = g.n
        g.tap(0); g.tap(0)                       // pearl at (0,0); it crosses out what it rules out
        XCTAssertEqual(g.mark(n + 1), .cross)
        g.tap(n + 1)                             // cross → pearl at (1,1), a corner touch
        XCTAssertEqual(g.conflicts, [0, n + 1])
        g.tap(n + 1)                             // clear it
        XCTAssertEqual(g.mark(3), .cross)
        g.tap(3)                                 // cross → pearl, same row
        XCTAssertEqual(g.conflicts, [0, 3])
        XCTAssertFalse(g.finished)
    }

    func testPearlsRecognisesTheAnswer() throws {
        let g = PearlsGame(date: monday)
        let answer = try XCTUnwrap(Self.solvePearls(g.puzzle.regions))
        for (r, c) in answer.enumerated() { g.tap(r * g.n + c); g.tap(r * g.n + c) }
        XCTAssertTrue(g.finished)
        XCTAssertNotNil(g.solvedIn)
        g.tap(answer[0])                          // row 0's pearl
        XCTAssertEqual(g.mark(answer[0]), .pearl, "a solved board is frozen")
    }

    func testPearlsRestoresASavedBoard() {
        let g = PearlsGame(date: monday)
        g.tap(5); g.tap(5)
        let then = Date(timeIntervalSinceNow: -90)
        let back = PearlsGame(date: monday, restoring: g.cells, startedAt: then)
        XCTAssertEqual(back.mark(5), .pearl)
        XCTAssertEqual(back.startedAt, then)
        XCTAssertFalse(back.finished)
    }

    /// The one answer, row by row, found by the same brute force the content tests use.
    static func solvePearls(_ reg: [[Int]]) -> [Int]? {
        let n = reg.count
        var usedC = Set<Int>(), usedR = Set<Int>(), cols: [Int] = []
        func rec(_ r: Int) -> Bool {
            if r == n { return true }
            for c in 0..<n {
                let k = reg[r][c]
                if usedC.contains(c) || usedR.contains(k) { continue }
                if let prev = cols.last, abs(c - prev) < 2 { continue }
                usedC.insert(c); usedR.insert(k); cols.append(c)
                if rec(r + 1) { return true }
                usedC.remove(c); usedR.remove(k); cols.removeLast()
            }
            return false
        }
        return rec(0) ? cols : nil
    }

    func testPearlsAPearlCrossesWhatItRulesOutAndLiftsItAgain() {
        let g = PearlsGame(date: monday)
        g.tap(0); g.tap(0)                        // pearl at (0,0)
        XCTAssertEqual(g.mark(0), .pearl)
        for j in g.cells.indices where g.sees(0, j) {
            XCTAssertEqual(g.mark(j), .cross, "cell \(j) should be crossed by the pearl")
        }
        XCTAssertTrue(g.cells.indices.contains { !g.sees(0, $0) && $0 != 0 && g.mark($0) == .blank })
        g.tap(0)                                  // pearl → blank
        XCTAssertEqual(g.mark(0), .blank)
        XCTAssertEqual(g.cells.filter { $0 != 0 }.count, 0, "its crosses lift with it")
    }

    func testPearlsUndoStepsBackOneMove() {
        let g = PearlsGame(date: monday)
        XCTAssertFalse(g.canUndo)
        g.tap(0)
        g.tap(0)
        XCTAssertTrue(g.canUndo)
        g.undo()
        XCTAssertEqual(g.mark(0), .cross, "back to the cross, before the pearl")
        XCTAssertEqual(g.cells.filter { $0 != 0 }.count, 1)
        g.undo()
        XCTAssertEqual(g.cells.filter { $0 != 0 }.count, 0)
        XCTAssertFalse(g.canUndo)
    }

    func testPearlsHintFixesAWrongPearlThenPlacesRightOnes() throws {
        let g = PearlsGame(date: monday)
        let answer = Set(try XCTUnwrap(g.solution))
        let wrong = try XCTUnwrap(g.cells.indices.first { !answer.contains($0) })
        g.tap(wrong); g.tap(wrong)
        XCTAssertEqual(g.mark(wrong), .pearl)
        g.hint()
        XCTAssertEqual(g.mark(wrong), .cross, "a wrong pearl is crossed out first")
        XCTAssertTrue(g.hintText?.contains("can't be right") == true)
        XCTAssertEqual(g.hints, 1)
        var guard_ = 0
        while !g.finished, guard_ < 20 { g.hint(); guard_ += 1 }
        XCTAssertTrue(g.finished, "hints alone finish the board")
        XCTAssertLessThanOrEqual(g.hints, g.n + 1)
        for i in g.cells.indices where g.mark(i) == .pearl { XCTAssertTrue(answer.contains(i)) }
    }

    // MARK: - Balance

    func testBalanceUndoAndHintWithAReason() throws {
        let g = BalanceGame(date: monday)
        let answer = try XCTUnwrap(g.solution)
        let i = try XCTUnwrap(g.cells.indices.first { !g.isGiven($0) })
        g.tap(i)
        XCTAssertTrue(g.canUndo)
        g.undo()
        XCTAssertEqual(g.cells[i], -1)
        // Make it wrong on purpose, then ask.
        while g.cells[i] == -1 || g.cells[i] == answer[i] { g.tap(i) }
        g.hint()
        XCTAssertEqual(g.cells[i], -1, "a wrong mark is cleared first")
        XCTAssertTrue(g.hintText?.contains("can't be right") == true)
        g.hint()
        XCTAssertEqual(g.hints, 2)
        let filled = try XCTUnwrap(g.cells.indices.first { !g.isGiven($0) && g.cells[$0] != -1 })
        XCTAssertEqual(g.cells[filled], answer[filled])
        XCTAssertFalse(g.hintText?.isEmpty ?? true)
        var guard_ = 0
        while !g.finished, guard_ < 40 { g.hint(); guard_ += 1 }
        XCTAssertTrue(g.finished)
        XCTAssertEqual(g.errors, [])
    }


    func testBalanceGivensDoNotMove() {
        let g = BalanceGame(date: monday)
        let given = g.cells.indices.first { g.isGiven($0) }!
        let before = g.cells[given]
        g.tap(given)
        XCTAssertEqual(g.cells[given], before)
        XCTAssertNil(g.startedAt, "tapping a given is not a move")
    }

    func testBalanceTapCyclesBlankDotRing() {
        let g = BalanceGame(date: monday)
        let free = g.cells.indices.first { !g.isGiven($0) }!
        g.tap(free); XCTAssertEqual(g.cells[free], 0)
        g.tap(free); XCTAssertEqual(g.cells[free], 1)
        g.tap(free); XCTAssertEqual(g.cells[free], -1)
    }

    func testBalanceFlagsThreeInARow() {
        let g = BalanceGame(date: monday)
        // Find a row with three free cells side by side and fill them alike.
        let n = g.n
        outer: for r in 0..<n {
            for c in 0..<(n - 2) {
                let run = [r * n + c, r * n + c + 1, r * n + c + 2]
                guard run.allSatisfy({ !g.isGiven($0) }) else { continue }
                for i in run { g.tap(i) }        // three dots
                XCTAssertTrue(g.errors.isSuperset(of: run))
                break outer
            }
        }
    }

    func testBalanceRecognisesTheAnswer() throws {
        let g = BalanceGame(date: monday)
        let answer = try XCTUnwrap(Self.solveBalance(g.puzzle.givens, signs: g.puzzle.signs))
        for i in g.cells.indices where !g.isGiven(i) {
            while g.cells[i] != answer[i] { g.tap(i) }
        }
        XCTAssertTrue(g.finished)
        XCTAssertEqual(g.errors, [])
    }

    static func solveBalance(_ givens: [[Int]], signs: [BalanceSign] = []) -> [Int]? {
        let n = givens.count
        var g = givens
        func ok(_ r: Int, _ c: Int, _ v: Int) -> Bool {
            g[r][c] = v; defer { g[r][c] = -1 }
            for s in signs where s.a == [r, c] || s.b == [r, c] {
                let o = s.a == [r, c] ? s.b : s.a
                if g[o[0]][o[1]] != -1, (g[o[0]][o[1]] == v) != s.same { return false }
            }
            if g[r].filter({ $0 == v }).count > n / 2 { return false }
            if (0..<n).filter({ g[$0][c] == v }).count > n / 2 { return false }
            for s in max(0, c - 2)...min(c, n - 3) where g[r][s] == v && g[r][s + 1] == v && g[r][s + 2] == v { return false }
            for s in max(0, r - 2)...min(r, n - 3) where g[s][c] == v && g[s + 1][c] == v && g[s + 2][c] == v { return false }
            return true
        }
        func rec(_ i: Int) -> Bool {
            if i == n * n { return true }
            let r = i / n, c = i % n
            if g[r][c] != -1 { return rec(i + 1) }
            for v in 0...1 where ok(r, c, v) {
                g[r][c] = v
                if rec(i + 1) { return true }
                g[r][c] = -1
            }
            return false
        }
        return rec(0) ? g.flatMap { $0 } : nil
    }
}

/// Sort and Weave, driven through their models on fixed boards.
@MainActor
final class PlayWordGameTests: XCTestCase {
    private let monday = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 7))!
    private let sortBoard = Catalog.fallbackSorts[0]
    private let weaveBoard = Catalog.fallbackWeaves[0]

    // MARK: Sort

    func testSortDealsSixteenAndLocksAGroup() {
        let g = SortGame(date: monday, puzzle: sortBoard)
        XCTAssertEqual(g.board.count, 16)
        XCTAssertEqual(Set(g.board), Set(0..<16))
        for w in 0..<4 { g.toggle(w) }
        XCTAssertEqual(g.selected.count, 4)
        g.toggle(5)
        XCTAssertEqual(g.selected.count, 4, "four is the most you can pick")
        XCTAssertEqual(g.submit(), .group(0))
        XCTAssertEqual(g.solved, [0])
        XCTAssertEqual(g.board.count, 12)
        XCTAssertTrue(g.selected.isEmpty)
        XCTAssertEqual(g.mistakes, 0)
    }

    func testSortOneAwayAndMissesEndAtFour() {
        let g = SortGame(date: monday, puzzle: sortBoard)
        for w in [0, 1, 2, 4] { g.toggle(w) }
        XCTAssertEqual(g.submit(), .oneAway)
        XCTAssertEqual(g.mistakes, 1)
        XCTAssertEqual(g.selected, [0, 1, 2, 4], "a miss keeps the pick so it can be fixed")
        XCTAssertEqual(g.submit(), .repeated, "the same four again is not a second miss")
        XCTAssertEqual(g.mistakes, 1)
        g.deselect()
        XCTAssertNil(g.submit(), "nothing picked, nothing to submit")
        for four in [[0, 4, 8, 12], [1, 5, 9, 13], [2, 6, 10, 14]] {
            for w in four { g.toggle(w) }
            XCTAssertEqual(g.submit(), .miss)
            g.deselect()
        }
        XCTAssertTrue(g.finished)
        XCTAssertFalse(g.won)
        XCTAssertEqual(g.shownGroups, [0, 1, 2, 3], "a loss shows every group")
    }

    func testSortWinsOnTheFourthGroupAndRestores() {
        let g = SortGame(date: monday, puzzle: sortBoard)
        for w in [0, 1, 2, 4] { g.toggle(w) }
        g.submit()
        g.deselect()
        for group in 0..<4 {
            for w in (group * 4)..<(group * 4 + 4) { g.toggle(w) }
            XCTAssertEqual(g.submit(), .group(group))
        }
        XCTAssertTrue(g.finished)
        XCTAssertTrue(g.won)
        XCTAssertEqual(g.mistakes, 1)
        XCTAssertEqual(g.progress.count, 20)
        let back = SortGame(date: monday, puzzle: sortBoard, restoring: g.progress)
        XCTAssertTrue(back.won)
        XCTAssertEqual(back.solved, [0, 1, 2, 3])
        XCTAssertEqual(back.mistakes, 1)
        XCTAssertEqual(SortGame(date: monday, puzzle: sortBoard, restoring: [0, 1, 2, 3]).board.count, 12)
        XCTAssertTrue(SortGame.isOver(g.progress))
        XCTAssertFalse(SortGame.isOver([0, 1, 2, 4]))
        XCTAssertTrue(SortGame.isOver([0, 1, 2, 4, 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14]))
    }

    func testSortShuffleKeepsTheSameWords() {
        let g = SortGame(date: monday, puzzle: sortBoard)
        var rng = SystemRandomNumberGenerator()
        g.shuffle(using: &rng)
        XCTAssertEqual(Set(g.board), Set(0..<16))
    }

    // MARK: Weave

    func testWeaveFindsThemeWordsOnTheirOwnCells() {
        let g = WeaveGame(date: monday, puzzle: weaveBoard)
        XCTAssertEqual(g.total, 8)
        for c in weaveBoard.words[0].c { g.touch(c) }
        XCTAssertEqual(g.spelled, "LATTES")
        XCTAssertEqual(g.submit(), .theme(0))
        XCTAssertEqual(g.foundCount, 1)
        XCTAssertTrue(g.path.isEmpty, "a submit clears the line")
        XCTAssertEqual(g.owner(6), .word(0))
        for c in weaveBoard.span.c { g.touch(c) }
        XCTAssertEqual(g.submit(), .span)
        XCTAssertEqual(g.owner(0), .span)
        XCTAssertFalse(g.touch(0), "a found letter is out of play")
        XCTAssertTrue(g.path.isEmpty)
    }

    func testWeaveTapRulesAndTooShort() {
        let g = WeaveGame(date: monday, puzzle: weaveBoard)
        XCTAssertFalse(g.touch(12))
        XCTAssertFalse(g.touch(13))
        XCTAssertTrue(g.touch(13), "landing on the end of the line is a submit-on-lift")
        XCTAssertEqual(g.submit(), .short)
        g.touch(12); g.touch(13); g.touch(14)
        XCTAssertFalse(g.touch(12), "tapping back into the line cuts it there")
        XCTAssertEqual(g.path, [12])
        g.touch(20)
        XCTAssertEqual(g.path, [20], "a far tap starts over")
    }

    func testWeaveExtrasEarnAHintThatOutlinesAWord() {
        let g = WeaveGame(date: monday, puzzle: weaveBoard)
        // Rows 3, 4, 5 read ROASTS, CREAMS, SUGARS; the first five letters of each
        // are real words that are not theme words.
        for c in 18...22 { g.touch(c) }                       // ROAST
        XCTAssertEqual(g.submit(), .extra)
        for c in 18...22 { g.touch(c) }
        XCTAssertEqual(g.submit(), .already)
        for c in (18...22).reversed() { g.touch(c) }          // TSAOR
        XCTAssertEqual(g.submit(), .notWord)
        XCTAssertEqual(g.hintsAvailable, 0)
        XCTAssertEqual(g.extrasToNextHint, 2)
        for c in 24...28 { g.touch(c) }                       // CREAM
        XCTAssertEqual(g.submit(), .extra)
        for c in 30...34 { g.touch(c) }                       // SUGAR
        XCTAssertEqual(g.submit(), .extra)
        XCTAssertEqual(g.extras, ["roast", "cream", "sugar"])
        XCTAssertEqual(g.hintsAvailable, 1)
        g.hint()
        XCTAssertEqual(g.hintsUsed, 1)
        XCTAssertEqual(g.revealed, 0, "the first hidden word is outlined")
        XCTAssertEqual(g.hintsAvailable, 0)
        XCTAssertTrue(g.isRevealed(6))
        g.hint()
        XCTAssertEqual(g.hintsUsed, 1, "one outline at a time")
        let back = WeaveGame(date: monday, puzzle: weaveBoard, restoring: g.progress)
        XCTAssertEqual(back.extras, g.extras)
        XCTAssertEqual(back.revealed, 0)
        XCTAssertEqual(back.hintsUsed, 1)
        for c in weaveBoard.words[0].c { g.touch(c) }
        XCTAssertEqual(g.submit(), .theme(0))
        XCTAssertNil(g.revealed, "finding the outlined word clears the outline")
    }

    func testWeaveFinishesWhenEveryWordIsFound() {
        let g = WeaveGame(date: monday, puzzle: weaveBoard)
        for w in weaveBoard.words {
            for c in w.c { g.touch(c) }
            g.submit()
        }
        XCTAssertFalse(g.finished)
        for c in weaveBoard.span.c { g.touch(c) }
        XCTAssertEqual(g.submit(), .span)
        XCTAssertTrue(g.finished)
        XCTAssertEqual(g.foundCount, g.total)
        XCTAssertTrue(WeaveGame(date: monday, puzzle: weaveBoard, restoring: g.progress).finished)
    }

    func testWeaveRightWordWrongCellsIsElsewhere() {
        let g = WeaveGame(date: monday, puzzle: weaveBoard)
        // The span is COFFEE on row 0. Spell it on the same cells but a different order: not possible,
        // so spell a theme word backwards, which is neither its cells' order nor a word.
        for c in weaveBoard.words[0].c.reversed() { g.touch(c) }
        XCTAssertEqual(g.spelled, "SETTAL")
        XCTAssertEqual(g.submit(), .notWord)
    }

    func testWeaveIsWordTakesPlainEndings() {
        XCTAssertTrue(WeaveGame.isWord("latte"))
        XCTAssertTrue(WeaveGame.isWord("lattes"))
        XCTAssertTrue(WeaveGame.isWord("roasted"))
        XCTAssertTrue(WeaveGame.isWord("roasting"))
        XCTAssertFalse(WeaveGame.isWord("xqzt"))
    }
}

/// Trace, driven through its model on a fixed 4×4 board: 1 top-left, 2 top-right,
/// 3 bottom-right, 4 bottom-left. The snake 0 1 2 3 7 6 5 4 8 9 10 11 15 14 13 12 solves it.
@MainActor
final class PlayTraceTests: XCTestCase {
    private let monday = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 7))!
    private let board = TracePuzzle(n: 4, numbers: [[1, 0, 0, 2], [0, 0, 0, 0], [0, 0, 0, 0], [4, 0, 0, 3]], walls: [])
    private let snake = [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11, 15, 14, 13, 12]

    func testTraceStartsOnOneAndRefusesBadSteps() {
        let g = TraceGame(date: monday, puzzle: board)
        XCTAssertEqual(g.path, [0], "the line starts on the 1")
        g.extend(to: 5)
        XCTAssertEqual(g.path, [0], "diagonal is not a step")
        g.extend(to: 4)
        XCTAssertEqual(g.path, [0, 4])
        g.extend(to: 8)
        g.extend(to: 12)
        XCTAssertEqual(g.path, [0, 4, 8], "the last number only takes the last step")
        g.extend(to: 9)
        g.extend(to: 13)
        XCTAssertEqual(g.path, [0, 4, 8, 9, 13], "plain cells are free")
        g.extend(to: 9)
        XCTAssertEqual(g.path, [0, 4, 8, 9], "dragging back onto the previous cell undoes a step")
        g.back()
        XCTAssertEqual(g.path, [0, 4, 8])
        g.clear()
        XCTAssertEqual(g.path, [0], "clear keeps the 1")
        g.back()
        XCTAssertEqual(g.path, [0], "the 1 never comes off")
    }

    func testTraceNumbersMustComeInOrder() {
        let g = TraceGame(date: monday, puzzle: board)
        for c in [4, 8, 9, 10, 11] { g.extend(to: c) }
        g.extend(to: 15)
        XCTAssertEqual(g.path.last, 11, "3 before 2 is refused")
        XCTAssertEqual(g.next, 2)
    }

    func testTraceFinishesOnTheLastNumber() {
        let g = TraceGame(date: monday, puzzle: board)
        for c in snake.dropFirst() { g.extend(to: c) }
        XCTAssertTrue(g.finished)
        XCTAssertNotNil(g.solvedIn)
        XCTAssertEqual(g.path.count, 16)
        g.extend(to: 0)
        g.back()
        XCTAssertEqual(g.path.count, 16, "a solved board is frozen")
    }

    func testTraceWallsBlockAStep() {
        let walled = TracePuzzle(n: 4, numbers: board.numbers, walls: [[0, 1]])
        let g = TraceGame(date: monday, puzzle: walled)
        g.extend(to: 1)
        XCTAssertEqual(g.path, [0], "a wall between 0 and 1")
        XCTAssertTrue(g.wall(between: 1, 0))
    }

    func testTraceHintWalksTheLineAndBacksUpAWrongTurn() throws {
        let g = TraceGame(date: monday, puzzle: board)
        let line = try XCTUnwrap(g.solution)
        XCTAssertEqual(line.count, 16)
        let wrongFirst = try XCTUnwrap([1, 4].first { $0 != line[1] })
        g.extend(to: wrongFirst)
        g.hint()
        XCTAssertEqual(g.path, [0], "a hint off the line backs up to where it left it")
        XCTAssertTrue(g.hintText?.contains("Back up") == true)
        g.hint()
        XCTAssertEqual(g.path, Array(line.prefix(2)))
        var guard_ = 0
        while !g.finished, guard_ < 20 { g.hint(); guard_ += 1 }
        XCTAssertTrue(g.finished)
        XCTAssertEqual(g.path, line)
        XCTAssertEqual(g.hints, 16)
    }

    func testTraceRestoresOnlyAValidPrefix() {
        let back = TraceGame(date: monday, puzzle: board, restoring: [0, 1, 2, 99, 3])
        XCTAssertEqual(back.path, [0, 1, 2], "a broken save stops at the first bad step")
        let full = TraceGame(date: monday, puzzle: board, restoring: snake, startedAt: monday)
        XCTAssertTrue(full.finished)
    }
}
