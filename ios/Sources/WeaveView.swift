import SwiftUI

// MARK: - Game model

/// A 6×8 of letters and a theme. Drag or tap through touching letters to spell
/// the theme words; one of them spans two opposite sides of the board and every
/// letter belongs to exactly one word. Any other real word of four letters or
/// more counts toward a hint: three of those earn one, and a hint outlines the
/// letters of a word still hidden. Built from the word-search; the board comes
/// from weaves.json.
@MainActor
final class WeaveGame: ObservableObject {
    enum Outcome: Equatable { case theme(Int), span, extra, already, notWord, short, elsewhere }

    let puzzle: WeavePuzzle
    let dealtDay: DayKey
    let number: Int
    /// The letters under the finger right now, first first.
    @Published private(set) var path: [Int] = []
    /// Theme word indices found so far.
    @Published private(set) var found: Set<Int> = []
    @Published private(set) var spanFound = false
    /// Real words that are not theme words, lowercase. Three earn a hint.
    @Published private(set) var extras: [String] = []
    @Published private(set) var hintsUsed = 0
    /// The theme word a hint has outlined, until it is found.
    @Published private(set) var revealed: Int?
    @Published private(set) var finished = false
    /// What the last submit did, for the kin line. Cleared by the next touch.
    @Published private(set) var last: Outcome?

    static let extrasPerHint = 3

    var cols: Int { puzzle.cols }
    var rows: Int { puzzle.rows }
    var total: Int { puzzle.words.count + 1 }
    var foundCount: Int { found.count + (spanFound ? 1 : 0) }
    var hintsAvailable: Int { extras.count / Self.extrasPerHint - hintsUsed }
    /// How many more non-theme words until the next hint.
    var extrasToNextHint: Int { Self.extrasPerHint - extras.count % Self.extrasPerHint }
    var spelled: String { path.map(puzzle.letter).joined() }

    /// The record: one line per find, in order.
    var progress: [String] {
        var out: [String] = []
        for (i, w) in puzzle.words.enumerated() where found.contains(i) { out.append("w:\(i):\(w.w)") }
        if spanFound { out.append("s") }
        for x in extras { out.append("x:\(x)") }
        for _ in 0..<hintsUsed { out.append("h") }
        if let revealed { out.append("r:\(revealed)") }
        return out
    }

    init(date: Date = Date(), calendar: Calendar = .current, puzzle fixed: WeavePuzzle? = nil,
         restoring saved: [String] = []) {
        number = PlayDeal.number(for: date, calendar: calendar)
        puzzle = fixed ?? PlayDeal.pick(Catalog.weaves, number: number) ?? Catalog.fallbackWeaves[0]
        dealtDay = DayKey(date, calendar: calendar)
        for line in saved {
            let parts = line.split(separator: ":").map(String.init)
            switch parts.first {
            case "w":
                if parts.count == 3, let i = Int(parts[1]), puzzle.words.indices.contains(i), puzzle.words[i].w == parts[2] {
                    found.insert(i)
                }
            case "s": spanFound = true
            case "x": if parts.count == 2 { extras.append(parts[1]) }
            case "h": hintsUsed += 1
            case "r": if parts.count == 2, let i = Int(parts[1]), puzzle.words.indices.contains(i), !found.contains(i) { revealed = i }
            default: break
            }
        }
        finished = foundCount == total
    }

    // MARK: Cells

    enum Owner: Equatable { case span, word(Int) }

    /// Which found word a cell belongs to, if any.
    func owner(_ cell: Int) -> Owner? {
        if spanFound, puzzle.span.c.contains(cell) { return .span }
        for i in found where puzzle.words[i].c.contains(cell) { return .word(i) }
        return nil
    }

    func isRevealed(_ cell: Int) -> Bool {
        guard let revealed else { return false }
        return puzzle.words[revealed].c.contains(cell)
    }

    func adjacent(_ a: Int, _ b: Int) -> Bool {
        let (ra, ca) = (a / cols, a % cols), (rb, cb) = (b / cols, b % cols)
        return a != b && abs(ra - rb) <= 1 && abs(ca - cb) <= 1
    }

    private func free(_ cell: Int) -> Bool { owner(cell) == nil }

    // MARK: Input

    /// A finger lands on a cell. Returns true when it landed on the end of the
    /// line, which a lift without moving turns into a submit.
    @discardableResult
    func touch(_ cell: Int) -> Bool {
        guard !finished, free(cell) else { return false }
        last = nil
        if path.last == cell { return true }
        if let k = path.firstIndex(of: cell) { path = Array(path[...k]); return false }
        if let head = path.last, adjacent(head, cell) { path.append(cell); return false }
        path = [cell]
        return false
    }

    /// The finger slides onto a cell: forward if it touches the head, back if it
    /// is the cell before the head. Anything else is ignored.
    func drag(to cell: Int) {
        guard !finished, free(cell) else { return }
        if path.count >= 2, cell == path[path.count - 2] { path.removeLast(); return }
        guard let head = path.last, adjacent(head, cell), !path.contains(cell) else { return }
        path.append(cell)
    }

    func clearPath() { path = [] }

    /// Checks the spelled line. Every outcome clears it.
    @discardableResult
    func submit() -> Outcome {
        defer { path = [] }
        guard !finished else { return .already }
        let word = spelled
        guard path.count >= 4 else { last = .short; return .short }
        let cells = Set(path)
        if word == puzzle.span.w {
            guard cells == Set(puzzle.span.c) else { last = .elsewhere; return .elsewhere }
            if spanFound { last = .already; return .already }
            spanFound = true
            last = .span
            finished = foundCount == total
            return .span
        }
        if let i = puzzle.words.firstIndex(where: { $0.w == word }) {
            guard cells == Set(puzzle.words[i].c) else { last = .elsewhere; return .elsewhere }
            if found.contains(i) { last = .already; return .already }
            found.insert(i)
            if revealed == i { revealed = nil }
            last = .theme(i)
            finished = foundCount == total
            return .theme(i)
        }
        let lower = word.lowercased()
        if extras.contains(lower) { last = .already; return .already }
        guard Self.isWord(lower) else { last = .notWord; return .notWord }
        extras.append(lower)
        last = .extra
        return .extra
    }

    /// Outlines the letters of the next hidden theme word. Costs one earned hint.
    func hint() {
        guard !finished, hintsAvailable > 0, revealed == nil,
              let next = puzzle.words.indices.first(where: { !found.contains($0) }) else { return }
        hintsUsed += 1
        revealed = next
        path = []
        last = nil
    }

    /// The dictionary, plus the plain plural and verb endings it leaves out.
    static func isWord(_ w: String) -> Bool {
        let d = Catalog.dictionary
        if d.contains(w) { return true }
        for (suffix, stems) in [("s", [""]), ("es", ["", "e"]), ("ed", ["", "e"]), ("ing", ["", "e"])] where w.hasSuffix(suffix) {
            let base = String(w.dropLast(suffix.count))
            for stem in stems where d.contains(base + stem) && (base + stem).count >= 4 { return true }
        }
        return false
    }

    /// Copies a restored round in. Same deal, so only the finds move.
    func adopt(_ other: WeaveGame) {
        guard other.puzzle == puzzle else { return }
        found = other.found
        spanFound = other.spanFound
        extras = other.extras
        hintsUsed = other.hintsUsed
        revealed = other.revealed
        finished = other.finished
        path = []
        last = nil
    }
}

// MARK: - Screen

struct WeaveView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var game: WeaveGame
    @State private var alreadyBanked = false
    @State private var paid: Int?
    /// The gesture in flight: the first cell it landed on, whether it landed on the
    /// end of the line, the last cell seen, and whether it moved.
    @State private var gestureFirst: Int?
    @State private var gestureOnEnd = false
    @State private var gestureLast: Int?
    @State private var gestureMoved = false
    @State private var shakes = 0

    private static let teal = Theme.hex(0x5CC8C0)
    private static let inkOnTeal = Theme.hex(0x0E4744)
    private static let eyebrowInk = Theme.hex(0x1F7E78)
    /// Board card (George's pick, 2026-09-10): letters in a white card, the theme
    /// as a teal band, the spelled word in a pill, ribbons through found words.
    private static let spanFill = Theme.hex(0xFFD36B)
    private static let wordFill = Theme.hex(0x7FD7B0)
    private static let pathFill = Theme.ink
    private static let band = Theme.hex(0xDDF3F0)
    private static let pillFill = Theme.hex(0xEFE8DD)

    init() {
        _game = StateObject(wrappedValue: WeaveGame())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                PlayHeader(fill: Self.teal, ink: Self.inkOnTeal, eyebrowInk: Self.eyebrowInk,
                           eyebrow: "WEAVE \(game.number) · \(game.foundCount) OF \(game.total)",
                           title: "Weave", line: "Find the theme words. One spans the board.",
                           banked: alreadyBanked || (paid ?? 0) > 0) { dismiss() }
                PlayKinLine(copy: kinCopy).padding(.top, 12)
                themeBand.padding(.top, 12)
                spelledLine.padding(.top, 10)
                boardCard.padding(.top, 8)
                foot.padding(.top, 10)
                Spacer(minLength: 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if game.finished {
                PlayEndCard(title: "Woven", line: endLine, paid: paid, share: share, ink: Self.inkOnTeal) { dismiss() }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Theme.paper)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.finished)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: game.foundCount)
        .onAppear {
            alreadyBanked = state.playClaimedToday
            if game.foundCount == 0, game.extras.isEmpty, !game.finished,
               let saved = state.playProgress(\.weavePlay, for: game.dealtDay), !saved.isEmpty {
                game.adopt(WeaveGame(restoring: saved))
            }
        }
    }

    // MARK: - Theme and the spelled line

    private var themeBand: some View {
        HStack {
            Text("THEME")
                .font(Theme.font(10.5, .black)).tracking(1.5)
                .foregroundStyle(Self.eyebrowInk)
            Spacer()
            Text(game.puzzle.theme)
                .font(Theme.font(16, .black)).tracking(-0.3)
                .foregroundStyle(Self.inkOnTeal)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14).frame(height: 40)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Self.band))
        .padding(.horizontal, 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's theme: \(game.puzzle.theme)")
    }

    private var spelledLine: some View {
        Text(game.spelled.isEmpty ? " " : game.spelled)
            .font(Theme.font(18, .black)).tracking(2)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 16).frame(height: 30)
            .background(Capsule().fill(Self.pillFill).opacity(game.spelled.isEmpty ? 0 : 1))
            .modifier(Shake(times: shakes))
            .accessibilityLabel(game.spelled.isEmpty ? "Nothing spelled yet" : "Spelling \(game.spelled)")
    }

    // MARK: - Board

    private var cell: CGFloat { 48 }

    private var boardCard: some View {
        board
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.card)
                .shadow(color: Theme.hex(0x2E2622).opacity(0.05), radius: 8, y: 2))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.tileRing, lineWidth: 1.5))
            .padding(.horizontal, 20)
    }
    private var boardWidth: CGFloat { cell * CGFloat(game.cols) }
    private var boardHeight: CGFloat { cell * CGFloat(game.rows) }

    private var board: some View {
        ZStack {
            // Lines through the found words, under the letters.
            Path { p in addLine(&p, game.puzzle.span.c) }
                .stroke(Self.spanFill, style: StrokeStyle(lineWidth: cell * 0.5, lineCap: .round, lineJoin: .round))
                .opacity(game.spanFound ? 1 : 0)
            ForEach(Array(game.found), id: \.self) { i in
                Path { p in addLine(&p, game.puzzle.words[i].c) }
                    .stroke(Self.wordFill, style: StrokeStyle(lineWidth: cell * 0.5, lineCap: .round, lineJoin: .round))
            }
            Path { p in addLine(&p, game.path) }
                .stroke(Self.pathFill, style: StrokeStyle(lineWidth: cell * 0.52, lineCap: .round, lineJoin: .round))
            ForEach(0..<(game.cols * game.rows), id: \.self) { i in letter(i) }
        }
        .frame(width: boardWidth, height: boardHeight)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    guard let i = cellAt(g.location) else { return }
                    if gestureFirst == nil {
                        gestureFirst = i
                        gestureLast = i
                        gestureMoved = false
                        gestureOnEnd = game.touch(i)
                        UISelectionFeedbackGenerator().selectionChanged()
                        return
                    }
                    guard i != gestureLast else { return }
                    gestureLast = i
                    gestureMoved = true
                    let before = game.path.count
                    game.drag(to: i)
                    if game.path.count != before { UISelectionFeedbackGenerator().selectionChanged() }
                }
                .onEnded { _ in
                    defer { gestureFirst = nil; gestureLast = nil; gestureMoved = false; gestureOnEnd = false }
                    if gestureMoved || gestureOnEnd { submit() }
                }
        )
        .disabled(game.finished)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Board, \(game.foundCount) of \(game.total) words found")
    }

    private func letter(_ i: Int) -> some View {
        let owner = game.owner(i)
        let onPath = owner == nil && game.path.contains(i)
        return Text(game.puzzle.letter(i))
            .font(Theme.font(20, .black))
            .foregroundStyle(onPath ? Theme.tabBar : Theme.ink)
            .frame(width: cell * 0.78, height: cell * 0.78)
            .overlay {
                if game.isRevealed(i) {
                    Circle().strokeBorder(Theme.coinDark, style: StrokeStyle(lineWidth: 2.5, dash: [4, 3]))
                }
            }
            .position(center(i))
            .accessibilityLabel(game.puzzle.letter(i) + (owner != nil ? ", found" : onPath ? ", selected" : ""))
    }

    private func center(_ i: Int) -> CGPoint {
        CGPoint(x: (CGFloat(i % game.cols) + 0.5) * cell, y: (CGFloat(i / game.cols) + 0.5) * cell)
    }

    /// The cell whose letter the finger is on. The corners between four letters
    /// count for nothing, so a diagonal drag picks the letter it actually crosses.
    private func cellAt(_ p: CGPoint) -> Int? {
        let c = Int(floor(p.x / cell)), r = Int(floor(p.y / cell))
        guard (0..<game.cols).contains(c), (0..<game.rows).contains(r) else { return nil }
        let i = r * game.cols + c
        let d = hypot(p.x - center(i).x, p.y - center(i).y)
        return d <= cell * 0.42 ? i : nil
    }

    private func addLine(_ p: inout Path, _ cells: [Int]) {
        guard let first = cells.first else { return }
        p.move(to: center(first))
        for c in cells.dropFirst() { p.addLine(to: center(c)) }
        if cells.count == 1 { p.addLine(to: center(first)) }
    }

    private var foot: some View {
        HStack {
            Text("\(game.foundCount) of \(game.total)")
                .font(Theme.font(12.5, .black))
                .foregroundStyle(Theme.muted)
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                game.hint(); save()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "lightbulb.fill").font(.system(size: 10.5, weight: .black))
                    Text(hintLabel).font(Theme.font(12, .black))
                }
                .foregroundStyle(game.hintsAvailable > 0 && game.revealed == nil ? Theme.coinDark : Theme.muted)
                .padding(.horizontal, 11).frame(height: 30)
                .background(Capsule().fill(game.hintsAvailable > 0 && game.revealed == nil ? Theme.coinSoft : Theme.tile))
            }
            .buttonStyle(PressStyle(scale: 0.95))
            .disabled(game.hintsAvailable == 0 || game.revealed != nil || game.finished)
            .accessibilityLabel(hintAccessibility)
        }
        .padding(.horizontal, 28)
        .opacity(game.finished ? 0 : 1)
    }

    private var hintLabel: String {
        if game.revealed != nil { return "Hint shown" }
        if game.hintsAvailable > 0 { return "Hint ready" }
        let n = game.extrasToNextHint
        return "Hint in \(n) word\(n == 1 ? "" : "s")"
    }

    private var hintAccessibility: String {
        if game.revealed != nil { return "A hint is already showing" }
        if game.hintsAvailable > 0 { return "Use a hint: outlines a hidden theme word" }
        return "\(game.extrasToNextHint) more real words earn a hint"
    }

    // MARK: - Copy

    private var kinCopy: String {
        if game.finished { return "Every letter, one word each." }
        switch game.last {
        case .theme: return game.total - game.foundCount == 1 ? "One left." : "Theme word. \(game.total - game.foundCount) to go."
        case .span: return "That's the one that spans the board."
        case .extra: return game.hintsAvailable > 0 ? "Real word. A hint is ready." : "Real word. \(game.extrasToNextHint) more for a hint."
        case .already: return "Already found that one."
        case .notWord: return "Not a word."
        case .short: return "Four letters at least."
        case .elsewhere: return "Right word, wrong spot. Try another path."
        case nil:
            if game.revealed != nil { return "The dashed letters spell a theme word." }
            if game.foundCount == 0 { return "Drag through letters. Any real word helps." }
            return "Keep going. Words bend any which way."
        }
    }

    private var endLine: String {
        "\(PlayHints.line(game.hintsUsed).capitalized). New board tomorrow."
    }

    private var share: String {
        "Prepkin Weave \(game.number) · \(game.total) words · \(PlayHints.line(game.hintsUsed))"
    }

    // MARK: - State

    private func submit() {
        let outcome = game.submit()
        switch outcome {
        case .theme, .span:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            save()
        case .extra:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            save()
        case .notWord, .elsewhere, .already:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default) { shakes += 1 }
        case .short:
            break
        }
    }

    private func save() {
        state.savePlayProgress(\.weavePlay, game.progress, day: game.dealtDay, puzzleRating: game.puzzle.rating)
        if game.finished, paid == nil {
            paid = state.recordPlaySolve(\.weavePlay, reason: .weave, dealtDay: game.dealtDay)
        }
    }
}

/// A short side-to-side shake, once per `times` change.
private struct Shake: GeometryEffect {
    var times: Int
    var animatableData: CGFloat {
        get { CGFloat(times) }
        set { shake = newValue }
    }
    private var shake: CGFloat = 0
    init(times: Int) { self.times = times; shake = CGFloat(times) }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 5 * sin(shake * .pi * 4), y: 0))
    }
}
