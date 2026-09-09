import SwiftUI

// MARK: - Game model

/// Zip-type path puzzle: one line from 1 through every cell, hitting the numbers
/// in order and ending on the last one, never crossing a wall. Drag to draw,
/// drag back to undo. The board comes from trace.json with a checked single
/// answer. Timed from the first move.
@MainActor
final class TraceGame: ObservableObject {
    let puzzle: TracePuzzle
    let dealtDay: DayKey
    let number: Int
    /// Cells visited so far, r*n+c, starting on the 1.
    @Published private(set) var path: [Int]
    @Published private(set) var finished = false
    @Published private(set) var startedAt: Date?
    private(set) var solvedIn: TimeInterval?
    @Published private(set) var hints = 0
    /// What the last hint did, for the kin line. Cleared by the next move.
    @Published private(set) var hintText: String?
    /// The one line, found on first use. Boards ship checked, so this is quick.
    lazy var solution: [Int]? = solve()

    var n: Int { puzzle.n }
    private let numbers: [Int]
    private let walls: Set<Int>
    let last: Int
    let startCell: Int

    init(date: Date = Date(), calendar: Calendar = .current, puzzle fixed: TracePuzzle? = nil,
         restoring saved: [Int]? = nil, startedAt: Date? = nil) {
        number = PlayDeal.number(for: date, calendar: calendar)
        puzzle = fixed ?? PlayDeal.pick(Catalog.trace, number: number) ?? Catalog.fallbackTrace[0]
        dealtDay = DayKey(date, calendar: calendar)
        let n = puzzle.n
        numbers = puzzle.numbers.flatMap { $0 }
        walls = Set(puzzle.walls.map { Self.wallKey($0[0], $0[1], n: n) })
        last = numbers.max() ?? 1
        startCell = numbers.firstIndex(of: 1) ?? 0
        path = [startCell]
        self.startedAt = startedAt
        if let saved, saved.first == startCell {
            // A save is replayed step by step and stops at the first bad one.
            for cell in saved.dropFirst() {
                guard canStep(to: cell) else { break }
                path.append(cell)
            }
        }
        if path.count == n * n {
            finished = true
            solvedIn = startedAt.map { Date().timeIntervalSince($0) } ?? 0
        }
    }

    private static func wallKey(_ a: Int, _ b: Int, n: Int) -> Int { min(a, b) * n * n + max(a, b) }

    func numberAt(_ cell: Int) -> Int { numbers[cell] }
    func wall(between a: Int, _ b: Int) -> Bool { walls.contains(Self.wallKey(a, b, n: n)) }
    func visited(_ cell: Int) -> Bool { path.contains(cell) }
    /// The number the path has to reach next.
    var next: Int { (path.compactMap { numbers[$0] == 0 ? nil : numbers[$0] }.max() ?? 0) + 1 }

    private func adjacent(_ a: Int, _ b: Int) -> Bool {
        let (ra, ca) = (a / n, a % n), (rb, cb) = (b / n, b % n)
        return abs(ra - rb) + abs(ca - cb) == 1
    }

    func canStep(to cell: Int) -> Bool {
        guard !finished, let head = path.last, cell != head, !visited(cell), numbers.indices.contains(cell),
              adjacent(head, cell), !wall(between: head, cell) else { return false }
        let num = numbers[cell]
        if num != 0, num != next { return false }
        if num == last, path.count != n * n - 1 { return false }
        return true
    }

    /// Drag onto a cell: step forward if allowed, or back if it is the cell
    /// before the head. Anything else is ignored, so a sloppy finger does nothing.
    func extend(to cell: Int, now: Date = Date()) {
        guard !finished else { return }
        if path.count >= 2, cell == path[path.count - 2] { back(); return }
        guard canStep(to: cell) else { return }
        if startedAt == nil { startedAt = now }
        hintText = nil
        path.append(cell)
        if path.count == n * n {
            finished = true
            solvedIn = now.timeIntervalSince(startedAt ?? now)
        }
    }

    func back() {
        guard !finished, path.count > 1 else { return }
        hintText = nil
        path.removeLast()
    }

    func clear() {
        guard !finished else { return }
        hintText = nil
        path = [startCell]
    }

    /// One step along the answer, or a step back to where the line left it.
    /// Free, counted.
    func hint(now: Date = Date()) {
        guard !finished, let line = solution else { return }
        if startedAt == nil { startedAt = now }
        hints += 1
        if let k = (0..<path.count).first(where: { path[$0] != line[$0] }) {
            path = Array(path[..<k])
            hintText = "Back up. The line went wrong after square \(k)."
            return
        }
        guard path.count < line.count else { return }
        path.append(line[path.count])
        hintText = "This way."
        if path.count == n * n {
            finished = true
            solvedIn = now.timeIntervalSince(startedAt ?? now)
        }
    }

    /// Depth-first for the line through every cell, numbers in order, ending on
    /// the last. A step budget keeps a pathological board from hanging the UI.
    private func solve() -> [Int]? {
        var used = Array(repeating: false, count: n * n)
        var steps = 0
        var out: [Int] = [startCell]
        used[startCell] = true
        func rec(_ i: Int, _ need: Int) -> Bool {
            steps += 1
            if steps > 400_000 { return false }
            if out.count == n * n { return need > last }
            let r = i / n, c = i % n
            for (dr, dc) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let rr = r + dr, cc = c + dc
                guard (0..<n).contains(rr), (0..<n).contains(cc) else { continue }
                let j = rr * n + cc
                if used[j] || wall(between: i, j) { continue }
                let num = numbers[j]
                if num != 0, num != need { continue }
                if num == last, out.count != n * n - 1 { continue }
                used[j] = true; out.append(j)
                if rec(j, num != 0 ? need + 1 : need) { return true }
                used[j] = false; out.removeLast()
            }
            return false
        }
        return rec(startCell, 2) ? out : nil
    }

    /// Copies a restored path in. Same deal, so only the line and clock move.
    func adopt(_ other: TraceGame) {
        guard other.puzzle == puzzle else { return }
        path = other.path
        startedAt = other.startedAt
        finished = other.finished
        solvedIn = other.solvedIn
        hints = other.hints
    }
}

// MARK: - Screen

struct TraceView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var game: TraceGame
    @State private var alreadyBanked = false
    @State private var paid: Int?
    @State private var dragCell: Int?

    private static let violet = Theme.hex(0x8B5CF6)
    private static let inkOnViolet = Theme.hex(0x2A1657)
    private static let eyebrowInk = Theme.hex(0x5B33C7)
    private static let line = Theme.hex(0xF0A24A)

    init() {
        _game = StateObject(wrappedValue: TraceGame())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                PlayHeader(fill: Self.violet, ink: Self.inkOnViolet, eyebrowInk: Self.eyebrowInk,
                           eyebrow: "TRACE \(game.number) · \(game.n)×\(game.n)",
                           title: "Trace", line: "One line, every square, numbers in order",
                           banked: alreadyBanked || (paid ?? 0) > 0) { dismiss() }
                PlayKinLine(copy: kinCopy).padding(.top, 14)
                board.padding(.top, 18)
                foot.padding(.top, 12)
                controls.padding(.top, 14)
                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if game.finished {
                PlayEndCard(title: "Traced in \(PlayClock.label(game.solvedIn ?? 0))",
                            line: "\(PlayHints.line(game.hints).capitalized). New board tomorrow.",
                            paid: paid, share: share, ink: Self.inkOnViolet) { dismiss() }
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
               let saved = state.playProgress(\.tracePlay, for: game.dealtDay) {
                game.adopt(TraceGame(restoring: saved, startedAt: state.playStartedAt(\.tracePlay, for: game.dealtDay)))
            }
        }
    }

    // MARK: - Board

    private var cell: CGFloat { game.n <= 6 ? 50 : 43 }
    private var boardSide: CGFloat { cell * CGFloat(game.n) }

    private var board: some View {
        let n = game.n
        return ZStack {
            // Paper grid.
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card)
            Path { p in
                for k in 1..<n {
                    let d = CGFloat(k) * cell
                    p.move(to: CGPoint(x: d, y: 0)); p.addLine(to: CGPoint(x: d, y: boardSide))
                    p.move(to: CGPoint(x: 0, y: d)); p.addLine(to: CGPoint(x: boardSide, y: d))
                }
            }
            .stroke(Theme.hairline, lineWidth: 1)
            // The line so far.
            Path { p in
                guard let first = game.path.first else { return }
                p.move(to: center(first))
                for c in game.path.dropFirst() { p.addLine(to: center(c)) }
            }
            .stroke(Self.line.opacity(game.finished ? 1 : 0.85),
                    style: StrokeStyle(lineWidth: cell * 0.46, lineCap: .round, lineJoin: .round))
            // Walls.
            Path { p in
                for w in game.puzzle.walls where w.count == 2 { addWall(&p, w[0], w[1]) }
            }
            .stroke(Theme.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            // Numbers.
            ForEach(0..<(n * n), id: \.self) { i in
                let num = game.numberAt(i)
                if num > 0 {
                    ZStack {
                        Circle().fill(Theme.ink)
                        Text("\(num)")
                            .font(Theme.font(cell * 0.34, .black))
                            .foregroundStyle(.white)
                    }
                    .frame(width: cell * 0.62, height: cell * 0.62)
                    .position(center(i))
                    .accessibilityLabel("Number \(num)" + (game.visited(i) ? ", on the line" : ""))
                }
            }
        }
        .frame(width: boardSide, height: boardSide)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.tileRing, lineWidth: 1.5))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    let c = Int(g.location.x / cell), r = Int(g.location.y / cell)
                    guard (0..<n).contains(c), (0..<n).contains(r) else { return }
                    let i = r * n + c
                    guard i != dragCell else { return }
                    dragCell = i
                    let before = game.path.count
                    game.extend(to: i)
                    if game.path.count != before { UISelectionFeedbackGenerator().selectionChanged() }
                }
                .onEnded { _ in dragCell = nil; save() }
        )
        .disabled(game.finished)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Board, \(game.path.count) of \(n * n) squares on the line")
    }

    private func center(_ i: Int) -> CGPoint {
        CGPoint(x: (CGFloat(i % game.n) + 0.5) * cell, y: (CGFloat(i / game.n) + 0.5) * cell)
    }

    /// A wall sits on the shared edge of two neighbours.
    private func addWall(_ p: inout Path, _ a: Int, _ b: Int) {
        let n = game.n
        let (lo, hi) = (min(a, b), max(a, b))
        let r = CGFloat(lo / n), c = CGFloat(lo % n)
        if hi == lo + 1 {          // side by side: vertical wall on lo's right edge
            let x = (c + 1) * cell
            p.move(to: CGPoint(x: x, y: r * cell + 3)); p.addLine(to: CGPoint(x: x, y: (r + 1) * cell - 3))
        } else {                   // stacked: horizontal wall on lo's bottom edge
            let y = (r + 1) * cell
            p.move(to: CGPoint(x: c * cell + 3, y: y)); p.addLine(to: CGPoint(x: (c + 1) * cell - 3, y: y))
        }
    }

    private var foot: some View {
        HStack {
            Text("\(game.path.count) of \(game.n * game.n)")
                .font(Theme.font(12.5, .black))
                .foregroundStyle(Theme.muted)
            Spacer()
            PlayStopwatch(since: game.startedAt, frozen: game.solvedIn)
        }
        .padding(.horizontal, 28)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            control("Undo", icon: "arrow.uturn.backward") { game.back(); save() }
            control("Clear", icon: "xmark") { game.clear(); save() }
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                game.hint(); save()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill").font(.system(size: 12, weight: .black))
                    Text(game.hints == 0 ? "Hint" : "Hint · \(game.hints)").font(Theme.font(14, .black))
                }
                .foregroundStyle(Theme.coinDark)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.coinSoft))
            }
            .buttonStyle(PressStyle(scale: 0.97))
            .accessibilityLabel("Hint: one step along the line")
        }
        .padding(.horizontal, 24)
        .opacity(game.finished ? 0 : 1)
    }

    private func control(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .black))
                Text(label).font(Theme.font(14, .black))
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity).frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.tileRing, lineWidth: 1.5))
        }
        .buttonStyle(PressStyle(scale: 0.97))
        .disabled(game.path.count <= 1)
    }

    // MARK: - Copy

    private var kinCopy: String {
        if game.finished { return "Every square, one line." }
        if let h = game.hintText { return h }
        if game.path.count == 1 { return "Drag from the 1. Hit the numbers in order." }
        let left = game.n * game.n - game.path.count
        if left <= 3 { return "Nearly. \(left) to go." }
        return "Next up: \(game.next). Drag back to undo."
    }

    private var share: String {
        "Prepkin Trace \(game.number) · \(PlayClock.label(game.solvedIn ?? 0)) · \(PlayHints.line(game.hints))"
    }

    // MARK: - State

    private func save() {
        state.savePlayProgress(\.tracePlay, game.path, startedAt: game.startedAt, day: game.dealtDay,
                               puzzleRating: game.puzzle.rating)
        if game.finished, paid == nil {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            paid = state.recordPlaySolve(\.tracePlay, reason: .trace, dealtDay: game.dealtDay)
        }
    }
}
