import XCTest
@testable import PrepkinCanvas

/// Reads the four Play puzzle files out of the built bundle and re-checks what the
/// generator promised: every puzzle is well formed and has exactly one answer. The
/// solvers here are small brute-force ones, on purpose separate from gen.py, so a
/// generator bug cannot vouch for itself.
final class PuzzleContentTests: XCTestCase {

    // MARK: - Ladders

    func testLaddersLoadAndAreFiveLetterWords() {
        XCTAssertGreaterThanOrEqual(Catalog.ladders.count, 300, "ladders.json did not load")
        for l in Catalog.ladders {
            XCTAssertEqual(l.start.count, 5, l.start)
            XCTAssertEqual(l.end.count, 5, l.end)
            XCTAssertTrue(Catalog.wordleAnswers.contains(l.start), "\(l.start) is not a common word")
            XCTAssertTrue(Catalog.wordleAnswers.contains(l.end), "\(l.end) is not a common word")
            XCTAssertTrue((3...6).contains(l.par), "\(l.start)→\(l.end) par \(l.par)")
        }
    }

    /// Par is the shortest path through the whole guess list, or a student could
    /// beat it and the end card would call an honest solve "over par".
    func testLadderParIsTheShortestPathThroughTheGuessList() {
        let words = Catalog.wordleGuesses
        var buckets: [String: [String]] = [:]
        for w in words {
            for i in 0..<5 {
                var k = Array(w); k[i] = "*"
                buckets[String(k), default: []].append(w)
            }
        }
        func neighbours(_ w: String) -> [String] {
            var out: [String] = []
            for i in 0..<5 {
                var k = Array(w); k[i] = "*"
                for n in buckets[String(k)] ?? [] where n != w { out.append(n) }
            }
            return out
        }
        for l in Catalog.ladders.prefix(120) {
            var dist = [l.start: 0]
            var queue = [l.start]
            var found = -1
            while !queue.isEmpty, found < 0 {
                let w = queue.removeFirst()
                if w == l.end { found = dist[w]!; break }
                if dist[w]! >= l.par { continue }
                for n in neighbours(w) where dist[n] == nil {
                    dist[n] = dist[w]! + 1
                    queue.append(n)
                }
            }
            XCTAssertEqual(found, l.par, "\(l.start)→\(l.end) says par \(l.par), shortest is \(found)")
        }
    }

    // MARK: - Threads

    func testThreadsHaveFiveCluesAndAnAnswer() {
        XCTAssertGreaterThanOrEqual(Catalog.threads.count, 20, "threads.json did not load")
        for t in Catalog.threads {
            XCTAssertEqual(t.clues.count, 5, t.id)
            XCTAssertFalse(t.name.isEmpty, t.id)
            XCTAssertFalse(t.accept.isEmpty, t.id)
            XCTAssertTrue(t.clues.allSatisfy { !$0.isEmpty }, t.id)
        }
        let ids = Catalog.threads.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "duplicate thread ids")
    }

    // MARK: - Balance

    func testBalancePuzzlesHaveExactlyOneAnswer() {
        XCTAssertGreaterThanOrEqual(Catalog.balance.count, 300, "balance.json did not load")
        for (i, p) in Catalog.balance.enumerated() {
            XCTAssertEqual(p.givens.count, p.n, "balance \(i)")
            XCTAssertTrue(p.givens.allSatisfy { $0.count == p.n }, "balance \(i)")
            XCTAssertTrue(p.givens.allSatisfy { $0.allSatisfy { (-1...1).contains($0) } }, "balance \(i)")
            let givens = p.givens.flatMap { $0 }.filter { $0 != -1 }.count
            XCTAssertTrue((10...24).contains(givens), "balance \(i) has \(givens) givens")
            XCTAssertEqual(Self.balanceSolutions(p.givens, limit: 2), 1, "balance \(i)")
        }
    }

    static func balanceOK(_ g: [[Int]], _ n: Int, _ r: Int, _ c: Int, _ v: Int) -> Bool {
        var g = g; g[r][c] = v
        if g[r].filter({ $0 == v }).count > n / 2 { return false }
        if (0..<n).filter({ g[$0][c] == v }).count > n / 2 { return false }
        for s in max(0, c - 2)...min(c, n - 3) where g[r][s] == v && g[r][s + 1] == v && g[r][s + 2] == v { return false }
        for s in max(0, r - 2)...min(r, n - 3) where g[s][c] == v && g[s + 1][c] == v && g[s + 2][c] == v { return false }
        return true
    }

    static func balanceSolutions(_ givens: [[Int]], limit: Int) -> Int {
        let n = givens.count
        var g = givens
        var count = 0
        func rec(_ i: Int) {
            if count >= limit { return }
            if i == n * n { count += 1; return }
            let r = i / n, c = i % n
            if g[r][c] != -1 { rec(i + 1); return }
            for v in 0...1 where balanceOK(g, n, r, c, v) {
                g[r][c] = v; rec(i + 1); g[r][c] = -1
            }
        }
        rec(0)
        return count
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
            [0, 0, 0, 1, 1, 1, 1],
            [0, 2, 2, 2, 1, 3, 1],
            [0, 2, 4, 2, 3, 3, 3],
            [5, 2, 4, 4, 4, 3, 6],
            [5, 5, 5, 4, 6, 6, 6],
            [5, 5, 5, 4, 6, 6, 6],
            [5, 5, 5, 5, 6, 6, 6]], limit: 2), 1)
    }
}
