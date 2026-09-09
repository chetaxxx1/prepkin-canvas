import SwiftUI

// MARK: - Game model

/// Queens-type Star Battle, one star: one pearl in every row, column and reef,
/// and no two pearls touching, corners included. Placing a pearl crosses out
/// every cell it rules out (lifted again if the pearl comes off). Undo steps
/// back a move; a hint fixes a wrong pearl or places the next forced one and
/// says why. The board comes from pearls.json, dealt by day, with one answer.
@MainActor
final class PearlsGame: ObservableObject {
    enum Mark: Int { case blank = 0, cross = 1, pearl = 2 }

    let puzzle: PearlsPuzzle
    let dealtDay: DayKey
    let number: Int
    /// One `Mark.rawValue` per cell, row-major. Ints so the record can save it as is.
    @Published private(set) var cells: [Int]
    @Published private(set) var finished = false
    /// First tap. The stopwatch runs from here; nil until the board is touched.
    @Published private(set) var startedAt: Date?
    /// Set when the board is solved, so the time shown stops moving.
    private(set) var solvedIn: TimeInterval?
    @Published private(set) var hints = 0
    /// What the last hint did, for the kin line. Cleared by the next move.
    @Published private(set) var hintText: String?
    /// Board and auto-cross map before each move, for undo.
    private var history: [(cells: [Int], auto: [Int: [Int]])] = []
    /// Pearl cell → the blank cells it crossed out when it was placed.
    private var auto: [Int: [Int]] = [:]
    /// The one answer, a cell per row. Found once, on first use.
    lazy var solution: [Int]? = Self.solve(puzzle)

    var n: Int { puzzle.n }
    var canUndo: Bool { !history.isEmpty && !finished }

    init(date: Date = Date(), calendar: Calendar = .current, restoring saved: [Int]? = nil, startedAt: Date? = nil) {
        number = PlayDeal.number(for: date, calendar: calendar)
        puzzle = Self.deal(for: date, calendar: calendar)
        dealtDay = DayKey(date, calendar: calendar)
        cells = Array(repeating: 0, count: puzzle.n * puzzle.n)
        self.startedAt = startedAt
        if let saved, saved.count == cells.count { cells = saved }
        if isSolved {
            finished = true
            solvedIn = startedAt.map { Date().timeIntervalSince($0) } ?? 0
        }
    }

    /// Weekdays deal a 7×7, Sunday the 8×8. Each size walks its own list so the
    /// Sunday boards don't get skipped through during the week.
    static func deal(for date: Date = Date(), calendar: Calendar = .current) -> PearlsPuzzle {
        let want = PlayDeal.isSunday(date, calendar: calendar) ? 8 : 7
        let pool = Catalog.pearls.filter { $0.n == want }
        let number = PlayDeal.number(for: date, calendar: calendar)
        return PlayDeal.pick(pool.isEmpty ? Catalog.pearls : pool, number: number)
            ?? PearlsPuzzle(n: 1, regions: [[0]])
    }

    func mark(_ i: Int) -> Mark { Mark(rawValue: cells[i]) ?? .blank }
    func region(_ i: Int) -> Int { puzzle.regions[i / n][i % n] }

    /// Tap cycles blank → cross → pearl → blank. A new pearl crosses out what it
    /// rules out; taking it off lifts those crosses. Nothing after the solve.
    func tap(_ i: Int, now: Date = Date()) {
        guard !finished, cells.indices.contains(i) else { return }
        if startedAt == nil { startedAt = now }
        snapshot()
        if mark(i) == .pearl { liftAuto(i) }
        cells[i] = (cells[i] + 1) % 3
        if mark(i) == .pearl { placeAuto(i) }
        settle(now: now)
    }

    /// Two cells rule each other out: same row, column or reef, or touching.
    func sees(_ a: Int, _ b: Int) -> Bool {
        guard a != b else { return false }
        let (r1, c1) = (a / n, a % n), (r2, c2) = (b / n, b % n)
        return r1 == r2 || c1 == c2 || region(a) == region(b) || (abs(r1 - r2) <= 1 && abs(c1 - c2) <= 1)
    }

    private func placeAuto(_ p: Int) {
        var crossed: [Int] = []
        for j in cells.indices where cells[j] == Mark.blank.rawValue && sees(p, j) {
            cells[j] = Mark.cross.rawValue
            crossed.append(j)
        }
        auto[p] = crossed
    }

    private func liftAuto(_ p: Int) {
        for j in auto[p] ?? [] where cells[j] == Mark.cross.rawValue
            && !auto.contains(where: { $0.key != p && $0.value.contains(j) }) {
            cells[j] = Mark.blank.rawValue
        }
        auto[p] = nil
    }

    private func snapshot() {
        history.append((cells, auto))
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
        cells = last.cells
        auto = last.auto
        hintText = nil
    }

    /// One step, explained: a wrong pearl comes off first; otherwise the next
    /// forced pearl goes down (a row, column or reef with one spot left), or
    /// failing that the answer's pearl for the first empty row. Free, counted.
    func hint(now: Date = Date()) {
        guard !finished, let answer = solution else { return }
        if startedAt == nil { startedAt = now }
        snapshot()
        hints += 1
        let answerSet = Set(answer)
        if let wrong = cells.indices.first(where: { cells[$0] == Mark.pearl.rawValue && !answerSet.contains($0) }) {
            liftAuto(wrong)
            cells[wrong] = Mark.cross.rawValue
            hintText = "The pearl in row \(wrong / n + 1) can't be right. Crossed it out."
            return
        }
        let pearls = cells.indices.filter { cells[$0] == Mark.pearl.rawValue }
        func open(_ i: Int) -> Bool { cells[i] == Mark.blank.rawValue && !pearls.contains { sees($0, i) } }
        var groups: [(name: String, cells: [Int])] = []
        for r in 0..<n { groups.append(("Row \(r + 1)", (0..<n).map { r * n + $0 })) }
        for c in 0..<n { groups.append(("Column \(c + 1)", (0..<n).map { $0 * n + c })) }
        for k in 0..<n {
            let cellsOf = cells.indices.filter { region($0) == k }
            groups.append(("The \(Self.reefName(k)) reef", cellsOf))
        }
        for g in groups where !g.cells.contains(where: { cells[$0] == Mark.pearl.rawValue }) {
            let spots = g.cells.filter(open)
            if spots.count == 1, answerSet.contains(spots[0]) {
                cells[spots[0]] = Mark.pearl.rawValue
                placeAuto(spots[0])
                hintText = "\(g.name) has one spot left."
                settle(now: now)
                return
            }
        }
        if let r = (0..<n).first(where: { r in !(0..<n).contains { cells[r * n + $0] == Mark.pearl.rawValue } }) {
            let cell = answer[r]
            cells[cell] = Mark.pearl.rawValue
            placeAuto(cell)
            hintText = "Row \(r + 1): it goes here."
            settle(now: now)
        }
    }

    /// Reef colours by index, in the order `PearlsView.reefs` paints them.
    static func reefName(_ k: Int) -> String {
        ["yellow", "blue", "peach", "green", "lilac", "pink", "lime", "cream", "teal"][k % 9]
    }

    /// The one answer, by rows: a column per row, no two in a column or reef,
    /// no two touching. Boards ship checked, so this is a formality that runs
    /// in well under a millisecond on 8×8.
    static func solve(_ p: PearlsPuzzle) -> [Int]? {
        let n = p.n
        var cols = Set<Int>(), reefs = Set<Int>(), out: [Int] = []
        func rec(_ r: Int) -> Bool {
            if r == n { return true }
            for c in 0..<n where !cols.contains(c) && !reefs.contains(p.regions[r][c]) {
                if let prev = out.last, abs(prev % n - c) < 2 { continue }
                cols.insert(c); reefs.insert(p.regions[r][c]); out.append(r * n + c)
                if rec(r + 1) { return true }
                cols.remove(c); reefs.remove(p.regions[r][c]); out.removeLast()
            }
            return false
        }
        return rec(0) ? out : nil
    }

    var pearlCount: Int { cells.filter { $0 == Mark.pearl.rawValue }.count }

    /// Every pearl that shares a row, column or reef with another, or touches one.
    /// The board shows these with a coral ring, so it teaches its own rules.
    var conflicts: Set<Int> {
        let pearls = cells.indices.filter { cells[$0] == Mark.pearl.rawValue }
        var bad = Set<Int>()
        for (a, i) in pearls.enumerated() {
            for j in pearls[(a + 1)...] {
                let (r1, c1) = (i / n, i % n), (r2, c2) = (j / n, j % n)
                if r1 == r2 || c1 == c2 || region(i) == region(j)
                    || (abs(r1 - r2) <= 1 && abs(c1 - c2) <= 1) {
                    bad.insert(i); bad.insert(j)
                }
            }
        }
        return bad
    }

    var isSolved: Bool { pearlCount == n && conflicts.isEmpty }
}

// MARK: - Screen

struct PearlsView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var game: PearlsGame
    /// Read once, before the solve is posted, so the end card tells the truth.
    @State private var alreadyBanked = false
    @State private var paid: Int?

    private static let sea = Theme.hex(0x4CA8E8)
    private static let inkOnSea = Theme.hex(0x0B3652)
    private static let eyebrowInk = Theme.hex(0x1F79B8)
    /// Reef colours. Nine, so an 8×8 never repeats one next to itself by index.
    static let reefs: [Color] = [0xFFE3A6, 0xCDE9FF, 0xFFD1CB, 0xDDF3E6, 0xE7DDFB,
                                 0xFBE0EC, 0xE6EFC8, 0xFFE9D2, 0xD9F0F2].map { Theme.hex($0) }

    init() {
        _game = StateObject(wrappedValue: PearlsGame())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                PlayHeader(fill: Self.sea, ink: Self.inkOnSea, eyebrowInk: Self.eyebrowInk,
                           eyebrow: "PEARLS \(game.number) · \(game.n)×\(game.n)",
                           title: "Pearls", line: "One per row, column and reef",
                           banked: alreadyBanked || (paid ?? 0) > 0) { dismiss() }
                PlayKinLine(copy: kinCopy).padding(.top, 14)
                board.padding(.top, 18)
                foot.padding(.top, 12)
                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if game.finished {
                PlayEndCard(title: "Placed in \(PlayClock.label(game.solvedIn ?? 0))",
                            line: endLine, paid: paid, share: share, ink: Self.inkOnSea) { dismiss() }
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
            // Restored on first appearance only. `init` cannot see `state`.
            if game.startedAt == nil, !game.finished,
               let saved = state.playProgress(\.pearlsPlay, for: game.dealtDay) {
                restore(saved, startedAt: state.playStartedAt(\.pearlsPlay, for: game.dealtDay))
            }
        }
    }

    // MARK: - Board

    private var side: CGFloat { game.n == 8 ? 41 : 46 }

    private var board: some View {
        let n = game.n
        let conflicts = game.conflicts
        return VStack(spacing: 0) {
            ForEach(0..<n, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<n, id: \.self) { c in
                        cell(r * n + c, conflict: conflicts.contains(r * n + c))
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.ink, lineWidth: 2.5))
    }

    private func cell(_ i: Int, conflict: Bool) -> some View {
        let n = game.n, r = i / n, c = i % n
        let reef = game.region(i)
        let wallAbove = r > 0 && game.puzzle.regions[r - 1][c] != reef
        let wallLeft = c > 0 && game.puzzle.regions[r][c - 1] != reef
        return Button { game.tap(i); save() } label: {
            ZStack {
                Rectangle().fill(Self.reefs[reef % Self.reefs.count])
                glyph(game.mark(i))
                if conflict {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Theme.coral, lineWidth: 3)
                        .padding(3)
                }
            }
            .frame(width: side, height: side)
            .overlay(alignment: .top) {
                Rectangle().fill(wallAbove ? Theme.ink : Theme.ink.opacity(0.12))
                    .frame(height: wallAbove ? 2.5 : 1)
            }
            .overlay(alignment: .leading) {
                Rectangle().fill(wallLeft ? Theme.ink : Theme.ink.opacity(0.12))
                    .frame(width: wallLeft ? 2.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(game.finished)
        .accessibilityLabel("Row \(r + 1), column \(c + 1), reef \(reef + 1)")
        .accessibilityValue(accessibilityMark(game.mark(i)) + (conflict ? ", conflict" : ""))
    }

    @ViewBuilder private func glyph(_ mark: PearlsGame.Mark) -> some View {
        switch mark {
        case .blank:
            EmptyView()
        case .cross:
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(Theme.ink.opacity(0.4))
        case .pearl:
            ZStack(alignment: .topLeading) {
                Circle().fill(.white)
                    .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2.5))
                Circle().fill(Theme.ink.opacity(0.16))
                    .frame(width: 5, height: 5)
                    .offset(x: 5, y: 5)
            }
            .frame(width: 22, height: 22)
        }
    }

    private func accessibilityMark(_ mark: PearlsGame.Mark) -> String {
        switch mark {
        case .blank: return "blank"
        case .cross: return "crossed out"
        case .pearl: return "pearl"
        }
    }

    private var foot: some View {
        HStack(spacing: 8) {
            Text("\(game.pearlCount) of \(game.n) pearls")
                .font(Theme.font(12.5, .black))
                .foregroundStyle(Theme.muted)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            if !game.finished {
                PlayControlButton(label: "Undo", icon: "arrow.uturn.backward") { game.undo(); save() }
                    .disabled(!game.canUndo).opacity(game.canUndo ? 1 : 0.45)
                PlayHintButton(count: game.hints, label: "Hint: place or fix one pearl, with the reason") { game.hint(); save() }
            }
            PlayStopwatch(since: game.startedAt, frozen: game.solvedIn)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Copy

    private var kinCopy: String {
        if game.finished { return "Not one touching. Clean." }
        if let h = game.hintText { return h }
        if !game.conflicts.isEmpty { return "Two are touching. One has to move." }
        switch game.pearlCount {
        case 0: return "One pearl per reef. Corners count as touching."
        case let k where k == game.n - 1: return "Last one."
        default: return "\(game.pearlCount) down, \(game.n - game.pearlCount) to go."
        }
    }

    private var endLine: String { "\(game.n) pearls, none touching, \(PlayHints.line(game.hints)). New reef tomorrow." }

    private var share: String {
        "Prepkin Pearls \(game.number) · \(game.n)×\(game.n) · \(PlayClock.label(game.solvedIn ?? 0)) · \(PlayHints.line(game.hints))"
    }

    // MARK: - State

    private func save() {
        state.savePlayProgress(\.pearlsPlay, game.cells, startedAt: game.startedAt, day: game.dealtDay,
                               puzzleRating: game.puzzle.rating)
        if game.finished, paid == nil {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            paid = state.recordPlaySolve(\.pearlsPlay, reason: .pearls, dealtDay: game.dealtDay)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func restore(_ saved: [Int], startedAt: Date?) {
        // The model is a `let` on the view, so a restored board is a fresh model
        // built from the save; SwiftUI re-renders off the published cells.
        let restored = PearlsGame(restoring: saved, startedAt: startedAt)
        game.adopt(restored)
    }
}

extension PearlsGame {
    /// Copies a restored board in. Same deal, so only the marks and clock move.
    func adopt(_ other: PearlsGame) {
        guard other.puzzle == puzzle else { return }
        cells = other.cells
        startedAt = other.startedAt
        finished = other.finished
        solvedIn = other.solvedIn
        hints = other.hints
    }
}
