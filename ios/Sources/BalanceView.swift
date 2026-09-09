import SwiftUI

// MARK: - Game model

/// Tango-type Takuzu: fill the grid with suns and moons so every row and column
/// has three of each, no three alike sit in a row, and every sign holds: = means
/// the two cells match, × means they differ. The board comes from balance.json,
/// dealt by day, with a checked single answer.
@MainActor
final class BalanceGame: ObservableObject {
    /// -1 blank, 0 sun, 1 moon — the same numbers the content file uses.
    let puzzle: BalancePuzzle
    let dealtDay: DayKey
    let number: Int
    @Published private(set) var cells: [Int]
    @Published private(set) var finished = false
    @Published private(set) var startedAt: Date?
    private(set) var solvedIn: TimeInterval?
    @Published private(set) var hints = 0
    /// What the last hint did and why, for the kin line. Cleared by the next move.
    @Published private(set) var hintText: String?
    private var history: [[Int]] = []
    /// The one answer, row-major. Found once, on first use.
    lazy var solution: [Int]? = Self.solve(puzzle)

    var n: Int { puzzle.n }
    var canUndo: Bool { !history.isEmpty && !finished }

    init(date: Date = Date(), calendar: Calendar = .current, puzzle fixed: BalancePuzzle? = nil,
         restoring saved: [Int]? = nil, startedAt: Date? = nil) {
        number = PlayDeal.number(for: date, calendar: calendar)
        puzzle = fixed ?? PlayDeal.pick(Catalog.balance, number: number) ?? BalancePuzzle(n: 2, givens: [[0, 1], [1, 0]])
        dealtDay = DayKey(date, calendar: calendar)
        cells = puzzle.givens.flatMap { $0 }
        self.startedAt = startedAt
        // A save only ever overwrites the cells that are not givens.
        if let saved, saved.count == cells.count {
            for i in cells.indices where !isGiven(i) { cells[i] = saved[i] }
        }
        if isSolved {
            finished = true
            solvedIn = startedAt.map { Date().timeIntervalSince($0) } ?? 0
        }
    }

    func isGiven(_ i: Int) -> Bool { puzzle.givens[i / n][i % n] != -1 }

    /// Tap cycles blank → sun → moon → blank. Givens don't move.
    func tap(_ i: Int, now: Date = Date()) {
        guard !finished, cells.indices.contains(i), !isGiven(i) else { return }
        if startedAt == nil { startedAt = now }
        snapshot()
        cells[i] = cells[i] == 1 ? -1 : cells[i] + 1
        settle(now: now)
    }

    private func snapshot() {
        history.append(cells)
        if history.count > 200 { history.removeFirst() }
        hintText = nil
    }

    private func settle(now: Date) {
        if isSolved {
            finished = true
            solvedIn = now.timeIntervalSince(startedAt ?? now)
        }
    }

    func undo() {
        guard !finished, let last = history.popLast() else { return }
        cells = last
        hintText = nil
    }

    static func word(_ v: Int) -> String { v == 0 ? "sun" : "moon" }

    /// One cell, with the rule that forces it: a wrong mark is cleared first;
    /// then a pair, a gap, a full line, or a sign. Failing all that, the answer's
    /// mark for the first blank. Free, counted.
    func hint(now: Date = Date()) {
        guard !finished, let answer = solution else { return }
        if startedAt == nil { startedAt = now }
        snapshot()
        hints += 1
        if let wrong = cells.indices.first(where: { cells[$0] != -1 && !isGiven($0) && cells[$0] != answer[$0] }) {
            hintText = "The \(Self.word(cells[wrong])) in row \(wrong / n + 1) can't be right. Cleared it."
            cells[wrong] = -1
            return
        }
        func place(_ i: Int, _ why: String) {
            cells[i] = answer[i]
            hintText = why
            settle(now: now)
        }
        var lines: [(name: String, cells: [Int])] = []
        for r in 0..<n { lines.append(("Row \(r + 1)", (0..<n).map { r * n + $0 })) }
        for c in 0..<n { lines.append(("Column \(c + 1)", (0..<n).map { $0 * n + c })) }
        for line in lines {
            let v = line.cells.map { cells[$0] }
            for i in 0..<(n - 1) where v[i] != -1 && v[i] == v[i + 1] {
                for j in [i - 1, i + 2] where (0..<n).contains(j) && v[j] == -1 {
                    return place(line.cells[j], "Two \(Self.word(v[i]))s in a row: the next one is a \(Self.word(1 - v[i])).")
                }
            }
            for i in 0..<(n - 2) where v[i] != -1 && v[i] == v[i + 2] && v[i + 1] == -1 {
                return place(line.cells[i + 1], "\(Self.word(v[i]).capitalized), blank, \(Self.word(v[i])): the middle is a \(Self.word(1 - v[i])).")
            }
            for k in 0...1 where v.filter({ $0 == k }).count == n / 2 {
                if let j = v.firstIndex(of: -1) {
                    return place(line.cells[j], "\(line.name) already has three \(Self.word(k))s: the rest are \(Self.word(1 - k))s.")
                }
            }
        }
        for s in signs {
            let (a, b) = (cells[s.a], cells[s.b])
            if a != -1, b == -1 { return place(s.b, s.same ? "= copies its neighbour: a \(Self.word(a))." : "× flips its neighbour: a \(Self.word(1 - a)).") }
            if b != -1, a == -1 { return place(s.a, s.same ? "= copies its neighbour: a \(Self.word(b))." : "× flips its neighbour: a \(Self.word(1 - b)).") }
        }
        if let i = cells.firstIndex(of: -1) {
            place(i, "Row \(i / n + 1), column \(i % n + 1) is a \(Self.word(answer[i])).")
        }
    }

    /// The one answer, by plain backtracking with the signs. Boards ship checked.
    static func solve(_ p: BalancePuzzle) -> [Int]? {
        let n = p.n
        var g = p.givens
        let signs = p.signs
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

    var filledCount: Int { cells.filter { $0 != -1 }.count }

    /// Both ends of each sign, as cell indices.
    var signs: [(a: Int, b: Int, same: Bool)] {
        puzzle.signs.compactMap { s in
            guard s.a.count == 2, s.b.count == 2 else { return nil }
            return (s.a[0] * n + s.a[1], s.b[0] * n + s.b[1], s.same)
        }
    }

    /// Cells breaking a rule right now: a run of three, more than half a line of
    /// one kind, or a sign that does not hold. Blank cells are never wrong.
    var errors: Set<Int> {
        var bad = Set<Int>()
        for s in signs where cells[s.a] != -1 && cells[s.b] != -1 && (cells[s.a] == cells[s.b]) != s.same {
            bad.formUnion([s.a, s.b])
        }
        func check(_ line: [Int]) {
            let v = line.map { cells[$0] }
            for k in 0...1 where v.filter({ $0 == k }).count > n / 2 {
                for (j, i) in line.enumerated() where v[j] == k { bad.insert(i) }
            }
            for s in 0..<(n - 2) where v[s] != -1 && v[s] == v[s + 1] && v[s] == v[s + 2] {
                bad.formUnion([line[s], line[s + 1], line[s + 2]])
            }
        }
        for r in 0..<n { check((0..<n).map { r * n + $0 }) }
        for c in 0..<n { check((0..<n).map { $0 * n + c }) }
        return bad
    }

    var isSolved: Bool { filledCount == n * n && errors.isEmpty }

    /// Copies a restored board in. Same deal, so only the marks and clock move.
    func adopt(_ other: BalanceGame) {
        guard other.puzzle == puzzle else { return }
        cells = other.cells
        startedAt = other.startedAt
        finished = other.finished
        solvedIn = other.solvedIn
        hints = other.hints
    }
}

// MARK: - Screen

struct BalanceView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var game: BalanceGame
    @State private var alreadyBanked = false
    @State private var paid: Int?

    private static let leaf = Theme.hex(0xA5CE6B)
    private static let inkOnLeaf = Theme.hex(0x2F4712)
    private static let eyebrowInk = Theme.hex(0x5C8A2A)

    init() {
        _game = StateObject(wrappedValue: BalanceGame())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                PlayHeader(fill: Self.leaf, ink: Self.inkOnLeaf, eyebrowInk: Self.eyebrowInk,
                           eyebrow: "BALANCE \(game.number)",
                           title: "Balance", line: "Three suns, three moons, every line",
                           banked: alreadyBanked || (paid ?? 0) > 0) { dismiss() }
                PlayKinLine(copy: kinCopy).padding(.top, 14)
                board.padding(.top, 18)
                foot.padding(.top, 12)
                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if game.finished {
                PlayEndCard(title: "Balanced in \(PlayClock.label(game.solvedIn ?? 0))",
                            line: endLine, paid: paid, share: share, ink: Self.inkOnLeaf) { dismiss() }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Theme.paper)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.finished)
        .onAppear {
            alreadyBanked = state.playClaimedToday
            if game.startedAt == nil, !game.finished,
               let saved = state.playProgress(\.balancePlay, for: game.dealtDay) {
                game.adopt(BalanceGame(restoring: saved,
                                       startedAt: state.playStartedAt(\.balancePlay, for: game.dealtDay)))
            }
        }
    }

    // MARK: - Board

    private var board: some View {
        let n = game.n
        let errors = game.errors
        return VStack(spacing: 5) {
            ForEach(0..<n, id: \.self) { r in
                HStack(spacing: 5) {
                    ForEach(0..<n, id: \.self) { c in
                        cell(r * n + c, error: errors.contains(r * n + c))
                    }
                }
            }
        }
        .overlay {
            // Signs sit on the gap between their two cells.
            ForEach(Array(game.signs.enumerated()), id: \.offset) { _, s in
                sign(s.same, error: errors.contains(s.a) && errors.contains(s.b))
                    .position(x: (CGFloat(s.a % n + s.b % n) / 2) * 51 + 23,
                              y: (CGFloat(s.a / n + s.b / n) / 2) * 51 + 23)
            }
        }
    }

    private func sign(_ same: Bool, error: Bool) -> some View {
        Text(same ? "=" : "×")
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(error ? Theme.coral : Theme.ink)
            .frame(width: 17, height: 17)
            .background(Circle().fill(Theme.card))
            .overlay(Circle().strokeBorder(error ? Theme.coral : Theme.tileRing, lineWidth: 1.5))
            .accessibilityLabel(same ? "Equals sign: these two match" : "Cross sign: these two differ")
    }

    private func cell(_ i: Int, error: Bool) -> some View {
        let given = game.isGiven(i)
        let ring: Color = error ? Theme.coral : (given ? Theme.tileRing : Theme.hairline)
        return Button { game.tap(i); save() } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(given ? Theme.tile : Theme.card)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ring, lineWidth: error ? 2.5 : 1.5)
                glyph(game.cells[i])
            }
            .frame(width: 46, height: 46)
        }
        .buttonStyle(PressStyle(scale: 0.94))
        .disabled(given || game.finished)
        .accessibilityLabel("Row \(i / game.n + 1), column \(i % game.n + 1)" + (given ? ", given" : ""))
        .accessibilityValue(name(game.cells[i]) + (error ? ", breaks a rule" : ""))
    }

    @ViewBuilder private func glyph(_ v: Int) -> some View {
        switch v {
        case 0: Image(systemName: "sun.max.fill").font(.system(size: 21, weight: .bold)).foregroundStyle(Theme.coin)
        case 1: Image(systemName: "moon.fill").font(.system(size: 19, weight: .bold)).foregroundStyle(Theme.hex(0x4C63D2))
        default: EmptyView()
        }
    }

    private func name(_ v: Int) -> String {
        switch v {
        case 0: return "sun"
        case 1: return "moon"
        default: return "blank"
        }
    }

    private var foot: some View {
        HStack(spacing: 8) {
            Text("\(game.filledCount) of \(game.n * game.n)")
                .font(Theme.font(12.5, .black))
                .foregroundStyle(Theme.muted)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            if !game.finished {
                PlayControlButton(label: "Undo", icon: "arrow.uturn.backward") { game.undo(); save() }
                    .disabled(!game.canUndo).opacity(game.canUndo ? 1 : 0.45)
                PlayHintButton(count: game.hints, label: "Hint: fill one cell, with the rule") { game.hint(); save() }
            }
            PlayStopwatch(since: game.startedAt, frozen: game.solvedIn)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Copy

    private var kinCopy: String {
        if game.finished { return "Every line, three and three." }
        if let h = game.hintText { return h }
        if !game.errors.isEmpty { return "Something there breaks a rule." }
        let left = game.n * game.n - game.filledCount
        switch left {
        case game.n * game.n - game.puzzle.givens.flatMap({ $0 }).filter({ $0 != -1 }).count:
            return game.signs.isEmpty ? "Two in a row means the next one flips." : "= match, × differ. Two in a row flips the next."
        case 1: return "Last one."
        default: return "\(left) to go."
        }
    }

    private var endLine: String { "\(PlayHints.line(game.hints).capitalized). New grid tomorrow." }

    private var share: String {
        "Prepkin Balance \(game.number) · \(PlayClock.label(game.solvedIn ?? 0)) · \(PlayHints.line(game.hints))"
    }

    // MARK: - State

    private func save() {
        state.savePlayProgress(\.balancePlay, game.cells, startedAt: game.startedAt, day: game.dealtDay,
                               puzzleRating: game.puzzle.rating)
        if game.finished, paid == nil {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            paid = state.recordPlaySolve(\.balancePlay, reason: .balance, dealtDay: game.dealtDay)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
