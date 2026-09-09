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

/// Ladder and Thread, driven through their models.
@MainActor
final class PlayWordGameTests: XCTestCase {
    private let monday = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 7))!

    private func type(_ word: String, into g: LadderGame) {
        for l in word.map(String.init) { g.key(l) }
    }

    /// Solves every middle rung by tapping it and typing its word, in whatever
    /// order the deal put them.
    private func solveMiddle(_ g: LadderGame) {
        for i in 1...5 {
            g.tapRow(i)
            XCTAssertEqual(g.selected, i)
            type(g.words[i], into: g)
            XCTAssertTrue(g.isSolved(i), g.words[i])
        }
    }

    /// Swaps rows until the middle reads `target`, top to bottom.
    private func arrange(_ g: LadderGame, _ target: [Int]) {
        for (pos, want) in target.enumerated() where g.order[pos] != want {
            g.tapRow(g.order[pos])     // pick up what sits there
            g.tapRow(want)             // drop it on the row that belongs there
        }
        XCTAssertEqual(g.order, target)
    }

    func testLadderChecksTheWordAsTheFifthLetterLands() {
        let g = LadderGame(date: monday)
        let i = try! XCTUnwrap(g.selected)
        XCTAssertEqual(g.rows.count, 5, "only the middle shows until it is ordered")
        type("ZZZZZ", into: g)
        XCTAssertEqual(g.wrong, i, "a wrong word is called out at once")
        XCTAssertEqual(g.typed[i], "ZZZZZ", "and stays on the row to be fixed")
        XCTAssertFalse(g.isSolved(i))
        g.key("A")
        XCTAssertEqual(g.typed[i], "A", "typing over a miss restarts the row")
        XCTAssertNil(g.wrong, "and clears the mark")
        g.backspace()
        type(g.words[i], into: g)
        XCTAssertTrue(g.isSolved(i))
        XCTAssertNotEqual(g.selected, i, "the cursor moves on to the next open rung")
        XCTAssertNotNil(g.startedAt, "the clock starts on the first letter")
    }

    func testLadderMiddleThenOrderThenTheEndRungs() {
        let g = LadderGame(date: monday)
        solveMiddle(g)
        XCTAssertTrue(g.middleDone)
        XCTAssertFalse(g.ordered, "the deal is never already in order")
        XCTAssertNil(g.selected, "nothing to type until the rungs are ordered")
        arrange(g, [1, 2, 3, 4, 5])
        XCTAssertTrue(g.ordered)
        XCTAssertEqual(g.rows, [0, 1, 2, 3, 4, 5, 6])
        XCTAssertEqual(g.selected, 0, "the top rung opens first")
        XCTAssertNil(g.lifted)
        g.tapRow(1)
        XCTAssertNil(g.lifted, "ordered rungs no longer pick up")
        type(g.words[0], into: g)
        XCTAssertEqual(g.selected, 6)
        type(g.words[6], into: g)
        XCTAssertTrue(g.finished)
        XCTAssertNotNil(g.solvedIn)
        XCTAssertEqual(g.solvedCount, 7)
    }

    func testLadderAMissClearsOnTheNextKeyOrTheTimer() {
        let g = LadderGame(date: monday)
        let i = try! XCTUnwrap(g.selected)
        type("ZZZZZ", into: g)
        XCTAssertEqual(g.wrong, i)
        let stamp = g.wrongStamp
        g.key("A")
        XCTAssertEqual(g.typed[i], "A", "typing over a miss starts the row again")
        XCTAssertNil(g.wrong)
        g.clearWrong(stamp: stamp)
        XCTAssertEqual(g.typed[i], "A", "a stale timer clears nothing")
        for _ in 0..<1 { g.backspace() }
        type("QQQQQ", into: g)
        g.clearWrong(stamp: g.wrongStamp)
        XCTAssertEqual(g.typed[i], "", "the timer clears the miss it saw")
        XCTAssertNil(g.wrong)
        type("PPPPP", into: g)
        g.backspace()
        XCTAssertEqual(g.typed[i], "", "delete on a miss clears the whole row")
    }

    func testLadderHintRevealsTheNextLetterAndDropsWrongOnes() {
        let g = LadderGame(date: monday)
        let i = try! XCTUnwrap(g.selected)
        let answer = g.words[i]
        g.hint()
        XCTAssertEqual(g.typed[i], String(answer.prefix(1)))
        XCTAssertEqual(g.hints, 1)
        XCTAssertNotNil(g.startedAt, "a hint starts the clock too")
        g.key("Z"); g.key("Z")
        g.hint()
        XCTAssertEqual(g.typed[i], String(answer.prefix(2)), "wrong letters after the reveal are dropped")
        for _ in 0..<3 { g.hint() }
        XCTAssertTrue(g.isSolved(i), "five hints spell the word and it locks like a typed one")
        XCTAssertEqual(g.hints, 5)
        XCTAssertNotEqual(g.selected, i)
    }

    func testLadderHintInTheOrderingStepMovesOneRungHome() {
        let g = LadderGame(date: monday)
        solveMiddle(g)
        let before = g.order
        while !g.ordered { g.hint() }
        XCTAssertNotEqual(before, g.order)
        XCTAssertLessThanOrEqual(g.hints, 4, "never more moves than rungs out of place")
        XCTAssertEqual(g.selected, g.top)
        let back = LadderGame(date: monday, restoring: g.progress)
        XCTAssertEqual(back.hints, g.hints, "the count survives a restore")
        XCTAssertTrue(back.ordered)
    }

    func testLadderLinksLightUpAsPairsMeet() {
        let g = LadderGame(date: monday)
        solveMiddle(g)
        arrange(g, [1, 2, 3, 4, 5])
        for (a, b) in zip(g.order, g.order.dropFirst()) { XCTAssertTrue(g.linked(a, b)) }
        XCTAssertFalse(g.linked(0, 1), "an end rung is not linked until it is typed")
        type(g.words[0], into: g)
        XCTAssertTrue(g.linked(0, 1))
        XCTAssertFalse(g.linked(1, 3), "two apart are not a link")
    }

    func testLadderAcceptsTheMiddleUpsideDown() {
        let g = LadderGame(date: monday)
        solveMiddle(g)
        arrange(g, [5, 4, 3, 2, 1])
        XCTAssertTrue(g.ordered)
        XCTAssertTrue(g.reversed)
        XCTAssertEqual(g.rows.first, 6, "the top rung is then the last word")
        XCTAssertEqual(g.selected, 6)
    }

    func testLadderRestoresTypedRowsAndOrder() {
        let g = LadderGame(date: monday)
        g.tapRow(g.order[2]); type(g.words[g.order[2]], into: g)
        g.tapRow(g.order[0]); type("QQQQQ", into: g)
        let back = LadderGame(date: monday, restoring: g.progress)
        XCTAssertEqual(back.typed, g.typed)
        XCTAssertEqual(back.order, g.order)
        XCTAssertFalse(back.finished)
        XCTAssertTrue(back.isSolved(g.order[2]))
    }

    func testThreadTurnsACluePerMissAndStopsAtFive() {
        let g = ThreadGame(date: monday)
        XCTAssertEqual(g.shown, 1)
        for i in 1...4 {
            XCTAssertFalse(g.guess("nope \(i)"))
            XCTAssertEqual(g.shown, i + 1)
        }
        XCTAssertFalse(g.finished)
        XCTAssertFalse(g.guess("still nope"))
        XCTAssertTrue(g.finished)
        XCTAssertEqual(g.got, 0)
        XCTAssertEqual(g.misses.count, 5)
    }

    func testThreadMatchingIgnoresFillerAndPlurals() {
        let p = ThreadPuzzle(id: "due", name: "Things that are due", accept: ["due"],
                             clues: ["Respect", "A baby", "Rent", "A library book", "An assignment"])
        XCTAssertTrue(ThreadGame.matches("things that are due", p))
        XCTAssertTrue(ThreadGame.matches("Due!", p))
        XCTAssertTrue(ThreadGame.matches("stuff that's due soon", p))
        XCTAssertFalse(ThreadGame.matches("things", p), "filler alone is not a guess")
        XCTAssertFalse(ThreadGame.matches("", p))
        let cards = ThreadPuzzle(id: "card", name: "___ card", accept: ["card"], clues: ["a", "b", "c", "d", "e"])
        XCTAssertTrue(ThreadGame.matches("kinds of cards", cards))
        XCTAssertTrue(ThreadGame.matches("CARD", cards))
    }

    func testThreadACloseMissIsCalledClose() {
        let p = ThreadPuzzle(id: "cc", name: "Credit card", accept: ["credit card"], clues: ["a", "b", "c", "d", "e"])
        XCTAssertTrue(ThreadGame.isClose("card", p))
        XCTAssertTrue(ThreadGame.isClose("kinds of cards", p))
        XCTAssertFalse(ThreadGame.isClose("zebra", p))
        XCTAssertFalse(ThreadGame.matches("card", p), "close is still a miss")
    }

    func testThreadHitScoresTheClueItWasGotOn() {
        let g = ThreadGame(date: monday)
        g.guess("wrong")
        g.guess("also wrong")
        XCTAssertTrue(g.guess(g.puzzle.accept[0]))
        XCTAssertEqual(g.got, 3)
        XCTAssertTrue(g.finished)
        let back = ThreadGame(date: monday, restoring: g.misses, solved: true)
        XCTAssertEqual(back.got, 3, "a solved round restores with its score")
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
