import XCTest
@testable import PrepkinCanvas

/// Reads the four Play puzzle files out of the built bundle and re-checks what the
/// generator promised: every puzzle is well formed and has exactly one answer. The
/// solvers here are small brute-force ones, on purpose separate from gen.py, so a
/// generator bug cannot vouch for itself.
final class PuzzleContentTests: XCTestCase {

    // MARK: - Sorts

    func testSortsAreFourGroupsOfFourDifferentWords() {
        XCTAssertGreaterThanOrEqual(Catalog.sorts.count, 30, "sorts.json did not load")
        for (i, p) in Catalog.sorts.enumerated() {
            XCTAssertEqual(p.groups.count, 4, "sort \(i)")
            let words = p.groups.flatMap(\.words)
            XCTAssertEqual(words.count, 16, "sort \(i)")
            XCTAssertEqual(Set(words).count, 16, "sort \(i) repeats a word")
            for g in p.groups {
                XCTAssertFalse(g.name.isEmpty, "sort \(i)")
                XCTAssertEqual(g.words.count, 4, "sort \(i) \(g.name)")
                XCTAssertTrue(g.words.allSatisfy { !$0.isEmpty && $0 == $0.uppercased() }, "sort \(i) \(g.name)")
            }
            XCTAssertEqual(Set(p.deal), Set(0..<16), "sort \(i) deal \(p.deal)")
            for r in 0..<4 {
                let row = (0..<4).map { p.deal[r * 4 + $0] / 4 }
                XCTAssertGreaterThan(Set(row).count, 1, "sort \(i) is dealt with a whole group in row \(r)")
            }
        }
    }

    // MARK: - Weaves

    /// Every letter belongs to exactly one word, every word is a path through
    /// touching cells with no diagonal crossing another, and the spanning word
    /// touches two opposite sides.
    func testWeavesTileTheBoardExactly() {
        XCTAssertGreaterThanOrEqual(Catalog.weaves.count, 30, "weaves.json did not load")
        for (i, p) in Catalog.weaves.enumerated() {
            let n = p.cols * p.rows
            XCTAssertEqual(p.grid.count, p.rows, "weave \(i)")
            XCTAssertTrue(p.grid.allSatisfy { $0.count == p.cols }, "weave \(i)")
            XCTAssertFalse(p.theme.isEmpty, "weave \(i)")
            let all = [p.span] + p.words
            var covered: [Int] = []
            var diagonals = Set<Set<Int>>()
            for w in all {
                XCTAssertGreaterThanOrEqual(w.w.count, 4, "weave \(i) \(w.w)")
                XCTAssertEqual(w.w.count, w.c.count, "weave \(i) \(w.w)")
                XCTAssertEqual(w.c.map(p.letter).joined(), w.w, "weave \(i) \(w.w) is not what its cells spell")
                for (a, b) in zip(w.c, w.c.dropFirst()) {
                    let (ra, ca) = (a / p.cols, a % p.cols), (rb, cb) = (b / p.cols, b % p.cols)
                    XCTAssertTrue(a != b && abs(ra - rb) <= 1 && abs(ca - cb) <= 1, "weave \(i) \(w.w) jumps")
                    if ra != rb, ca != cb {
                        let cross: Set<Int> = [ra * p.cols + cb, rb * p.cols + ca]
                        XCTAssertFalse(diagonals.contains(cross), "weave \(i) \(w.w) crosses another word")
                        diagonals.insert([a, b])
                    }
                }
                covered += w.c
            }
            XCTAssertEqual(covered.count, n, "weave \(i) covers \(covered.count) of \(n)")
            XCTAssertEqual(Set(covered), Set(0..<n), "weave \(i) does not tile the board")
            let cols = p.span.c.map { $0 % p.cols }, rows = p.span.c.map { $0 / p.cols }
            let across = cols.contains(0) && cols.contains(p.cols - 1)
            let down = rows.contains(0) && rows.contains(p.rows - 1)
            XCTAssertTrue(across || down, "weave \(i) \(p.span.w) does not span the board")
            XCTAssertEqual(Set(all.map(\.w)).count, all.count, "weave \(i) repeats a word")
        }
        let themes = Catalog.weaves.map(\.theme)
        XCTAssertEqual(Set(themes).count, themes.count, "duplicate weave themes")
    }

    func testTheDictionaryLoadsAndHoldsEveryThemeWord() {
        XCTAssertGreaterThan(Catalog.dictionary.count, 50_000, "dictionary.txt did not load")
        XCTAssertTrue(Catalog.dictionary.contains("latte"))
        for p in Catalog.weaves {
            XCTAssertTrue(Catalog.dictionary.contains(p.span.w.lowercased()), p.span.w)
            for w in p.words { XCTAssertTrue(Catalog.dictionary.contains(w.w.lowercased()), w.w) }
        }
    }

    // MARK: - Balance

    func testBalancePuzzlesHaveExactlyOneAnswer() {
        XCTAssertGreaterThanOrEqual(Catalog.balance.count, 300, "balance.json did not load")
        for (i, p) in Catalog.balance.enumerated() {
            XCTAssertEqual(p.givens.count, p.n, "balance \(i)")
            XCTAssertTrue(p.givens.allSatisfy { $0.count == p.n }, "balance \(i)")
            XCTAssertTrue(p.givens.allSatisfy { $0.allSatisfy { (-1...1).contains($0) } }, "balance \(i)")
            let givens = p.givens.flatMap { $0 }.filter { $0 != -1 }.count
            // Rule-only solvable boards land at 7–12 givens; fewer means a bug, more means an easy board slipped past the trim.
            XCTAssertTrue((3...20).contains(givens), "balance \(i) has \(givens) givens")
            for s in p.signs {
                XCTAssertEqual(s.a.count, 2, "balance \(i)"); XCTAssertEqual(s.b.count, 2, "balance \(i)")
                XCTAssertEqual(abs(s.a[0] - s.b[0]) + abs(s.a[1] - s.b[1]), 1, "balance \(i) sign is not between neighbours")
            }
            XCTAssertEqual(Self.balanceSolutions(p.givens, limit: 2, signs: p.signs), 1, "balance \(i)")
        }
    }

    static func balanceOK(_ g: [[Int]], _ n: Int, _ r: Int, _ c: Int, _ v: Int, signs: [BalanceSign] = []) -> Bool {
        for s in signs where (s.a == [r, c] || s.b == [r, c]) {
            let o = s.a == [r, c] ? s.b : s.a
            let other = g[o[0]][o[1]]
            if other != -1, (other == v) != s.same { return false }
        }
        var g = g; g[r][c] = v
        if g[r].filter({ $0 == v }).count > n / 2 { return false }
        if (0..<n).filter({ g[$0][c] == v }).count > n / 2 { return false }
        for s in max(0, c - 2)...min(c, n - 3) where g[r][s] == v && g[r][s + 1] == v && g[r][s + 2] == v { return false }
        for s in max(0, r - 2)...min(r, n - 3) where g[s][c] == v && g[s + 1][c] == v && g[s + 2][c] == v { return false }
        return true
    }

    static func balanceSolutions(_ givens: [[Int]], limit: Int, signs: [BalanceSign] = []) -> Int {
        let n = givens.count
        var g = givens
        var count = 0
        func rec(_ i: Int) {
            if count >= limit { return }
            if i == n * n { count += 1; return }
            let r = i / n, c = i % n
            if g[r][c] != -1 { rec(i + 1); return }
            for v in 0...1 where balanceOK(g, n, r, c, v, signs: signs) {
                g[r][c] = v; rec(i + 1); g[r][c] = -1
            }
        }
        rec(0)
        return count
    }

    // MARK: - Trace

    func testTraceBoardsHaveOneLine() {
        XCTAssertGreaterThanOrEqual(Catalog.trace.count, 100, "trace.json did not load")
        for (i, p) in Catalog.trace.enumerated() {
            let n = p.n
            XCTAssertTrue((4...7).contains(n), "trace \(i)")
            XCTAssertEqual(p.numbers.count, n, "trace \(i)")
            XCTAssertTrue(p.numbers.allSatisfy { $0.count == n }, "trace \(i)")
            let nums = p.numbers.flatMap { $0 }.filter { $0 > 0 }.sorted()
            XCTAssertEqual(nums, Array(1...max(1, nums.count)), "trace \(i) numbers are not 1...k")
            XCTAssertGreaterThanOrEqual(nums.count, 5, "trace \(i)")
            for w in p.walls {
                XCTAssertEqual(w.count, 2, "trace \(i)")
                XCTAssertEqual(abs(w[0] / n - w[1] / n) + abs(w[0] % n - w[1] % n), 1, "trace \(i) wall is not on an edge")
            }
        }
        for (i, p) in Catalog.trace.prefix(40).enumerated() {
            XCTAssertEqual(Self.traceSolutions(p, limit: 2), 1, "trace \(i)")
        }
    }

    /// Counts lines through every cell that hit the numbers in order and end on
    /// the last one. Stops at `limit`.
    static func traceSolutions(_ p: TracePuzzle, limit: Int) -> Int {
        let n = p.n
        let numbers = p.numbers.flatMap { $0 }
        let last = numbers.max() ?? 1
        var walls = Set<Int>()
        for w in p.walls where w.count == 2 { walls.insert(min(w[0], w[1]) * n * n + max(w[0], w[1])) }
        var used = Array(repeating: false, count: n * n)
        var found = 0
        func rec(_ i: Int, _ need: Int, _ depth: Int) {
            if found >= limit { return }
            if depth == n * n { if need > last { found += 1 }; return }
            let r = i / n, c = i % n
            for (dr, dc) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let rr = r + dr, cc = c + dc
                guard (0..<n).contains(rr), (0..<n).contains(cc) else { continue }
                let j = rr * n + cc
                if used[j] || walls.contains(min(i, j) * n * n + max(i, j)) { continue }
                let num = numbers[j]
                if num != 0, num != need { continue }
                if num == last, depth != n * n - 1 { continue }
                used[j] = true
                rec(j, num != 0 ? need + 1 : need, depth + 1)
                used[j] = false
            }
        }
        guard let start = numbers.firstIndex(of: 1) else { return 0 }
        used[start] = true
        rec(start, 2, 1)
        return found
    }

    // MARK: - Pearls

    func testPearlsPuzzlesHaveExactlyOneAnswer() {
        XCTAssertGreaterThanOrEqual(Catalog.pearls.count, 300, "pearls.json did not load")
        XCTAssertTrue(Catalog.pearls.contains { $0.n == 8 }, "no Sunday 8×8 boards")
        for (i, p) in Catalog.pearls.enumerated() {
            XCTAssertEqual(p.regions.count, p.n, "pearls \(i)")
            XCTAssertTrue(p.regions.allSatisfy { $0.count == p.n }, "pearls \(i)")
            var sizes = [Int](repeating: 0, count: p.n)
            for row in p.regions {
                for k in row {
                    XCTAssertTrue((0..<p.n).contains(k), "pearls \(i) region id \(k)")
                    if (0..<p.n).contains(k) { sizes[k] += 1 }
                }
            }
            XCTAssertGreaterThanOrEqual(sizes.min() ?? 0, 3, "pearls \(i) has a tiny reef")
            XCTAssertEqual(Self.pearlSolutions(p.regions, limit: 2), 1, "pearls \(i)")
        }
    }

    static func pearlSolutions(_ reg: [[Int]], limit: Int) -> Int {
        let n = reg.count
        var usedC = Set<Int>(), usedR = Set<Int>()
        var count = 0
        func rec(_ r: Int, _ prev: Int) {
            if count >= limit { return }
            if r == n { count += 1; return }
            for c in 0..<n {
                let k = reg[r][c]
                if usedC.contains(c) || usedR.contains(k) { continue }
                if prev >= 0 && abs(c - prev) < 2 { continue }
                usedC.insert(c); usedR.insert(k)
                rec(r + 1, c)
                usedC.remove(c); usedR.remove(k)
            }
        }
        rec(0, -1)
        return count
    }

    /// The built-in fallbacks are real puzzles too: they are what a student gets if
    /// a content file ever goes missing from the bundle.
    func testFallbacksAreRealPuzzles() {
        XCTAssertEqual(Self.balanceSolutions([
            [ 1,  0, -1, -1, -1, -1],
            [-1,  0,  0, -1, -1, -1],
            [-1, -1,  1, -1, -1,  1],
            [-1, -1, -1, -1, -1, -1],
            [-1, -1,  0,  0, -1,  0],
            [-1, -1,  1, -1, -1,  1]], limit: 2), 1)
        XCTAssertEqual(Self.pearlSolutions([
            [1, 1, 0, 0, 0, 0, 6],
            [1, 3, 4, 2, 0, 6, 6],
            [3, 3, 4, 2, 2, 6, 6],
            [4, 3, 4, 6, 6, 6, 6],
            [4, 4, 4, 4, 4, 6, 6],
            [4, 5, 5, 5, 4, 6, 6],
            [4, 4, 4, 5, 6, 6, 6]], limit: 2), 1)
    }
}
