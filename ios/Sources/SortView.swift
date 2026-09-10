import SwiftUI

// MARK: - Game model

/// Sixteen words, four hidden groups of four. Pick four and submit: a group locks
/// in with its name, three of four is "one away", anything else is a miss. Four
/// misses and the rest of the groups are shown, no coins, nothing lost. Built
/// from the connecting-wall quiz format; the board comes from sorts.json.
@MainActor
final class SortGame: ObservableObject {
    enum Outcome: Equatable { case group(Int), oneAway, miss, repeated }

    let puzzle: SortPuzzle
    let dealtDay: DayKey
    let number: Int
    /// Word indices still on the board, in display order.
    @Published private(set) var board: [Int]
    @Published private(set) var selected: [Int] = []
    /// Group indices in the order they were found.
    @Published private(set) var solved: [Int] = []
    /// Every submitted set of four, sorted, in order. The whole record.
    @Published private(set) var guesses: [[Int]] = []
    @Published private(set) var finished = false
    @Published private(set) var won = false
    /// What the last submit did, for the kin line. Cleared by the next tap.
    @Published private(set) var last: Outcome?

    static let maxMisses = 4

    init(date: Date = Date(), calendar: Calendar = .current, puzzle fixed: SortPuzzle? = nil,
         restoring saved: [Int] = []) {
        number = PlayDeal.number(for: date, calendar: calendar)
        puzzle = fixed ?? PlayDeal.pick(Catalog.sorts, number: number) ?? Catalog.fallbackSorts[0]
        dealtDay = DayKey(date, calendar: calendar)
        board = puzzle.deal.count == 16 ? puzzle.deal : Array(0..<16)
        // A save is replayed four at a time and stops at the first bad one.
        var i = 0
        while i + 4 <= saved.count, !finished {
            let four = Array(saved[i..<(i + 4)])
            guard Set(four).count == 4, four.allSatisfy({ (0..<16).contains($0) && board.contains($0) }) else { break }
            selected = four
            submit()
            i += 4
        }
        selected = []
        last = nil
    }

    func group(of word: Int) -> Int { word / 4 }
    func isGroup(_ four: [Int]) -> Bool { Set(four.map(group(of:))).count == 1 && four.count == 4 }
    var mistakes: Int { guesses.filter { !isGroup($0) }.count }
    var missesLeft: Int { max(0, Self.maxMisses - mistakes) }
    var progress: [Int] { guesses.flatMap { $0 } }
    /// The groups to show, found ones first, then (after a loss) the rest.
    var shownGroups: [Int] { finished && !won ? solved + (0..<4).filter { !solved.contains($0) } : solved }

    func toggle(_ word: Int) {
        guard !finished, board.contains(word) else { return }
        last = nil
        if let k = selected.firstIndex(of: word) { selected.remove(at: k); return }
        guard selected.count < 4 else { return }
        selected.append(word)
    }

    func deselect() { last = nil; selected = [] }

    func shuffle<G: RandomNumberGenerator>(using rng: inout G) {
        guard !finished else { return }
        last = nil
        board.shuffle(using: &rng)
    }

    /// True on a group. A miss counts against the four; three of four says so.
    @discardableResult
    func submit() -> Outcome? {
        guard !finished, selected.count == 4 else { return nil }
        let four = selected.sorted()
        if guesses.contains(four) { last = .repeated; return .repeated }
        guesses.append(four)
        if isGroup(four) {
            let g = group(of: four[0])
            solved.append(g)
            board.removeAll { four.contains($0) }
            selected = []
            last = .group(g)
            if solved.count == 4 { finished = true; won = true }
            return .group(g)
        }
        let counts = Dictionary(grouping: four, by: group(of:)).values.map(\.count)
        last = counts.contains(3) ? .oneAway : .miss
        if mistakes >= Self.maxMisses { finished = true; selected = [] }
        return last
    }

    /// Whether a saved record is a finished board, for the rail. Word `i` is in
    /// group `i / 4` on every board, so this needs no puzzle.
    nonisolated static func isOver(_ progress: [Int]) -> Bool {
        var misses = 0, groups = 0
        var i = 0
        while i + 4 <= progress.count {
            if Set(progress[i..<(i + 4)].map { $0 / 4 }).count == 1 { groups += 1 } else { misses += 1 }
            i += 4
        }
        return misses >= maxMisses || groups == 4
    }
}

// MARK: - Screen

struct SortView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var game: SortGame
    @State private var alreadyBanked = false
    @State private var paid: Int?
    @State private var shakes = 0

    private static let orange = Theme.hex(0xF5A15C)
    private static let inkOnOrange = Theme.hex(0x5A2A0E)
    private static let eyebrowInk = Theme.hex(0xB35A18)
    /// One fill per group, easiest first. Our own order, not anyone else's.
    static let groupFills = [Theme.hex(0xBDE8D2), Theme.hex(0xFFE2A0), Theme.hex(0xF9C4CF), Theme.hex(0xD3C6F5)]

    init() {
        _game = StateObject(wrappedValue: SortGame())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                PlayHeader(fill: Self.orange, ink: Self.inkOnOrange, eyebrowInk: Self.eyebrowInk,
                           eyebrow: "SORT \(game.number) · \(game.solved.count) OF 4",
                           title: "Sort", line: "Four groups of four",
                           banked: alreadyBanked || (paid ?? 0) > 0) { dismiss() }
                PlayKinLine(copy: kinCopy).padding(.top, 14)
                boardArea.padding(.top, 16)
                foot.padding(.top, 14)
                if !game.finished { controls.padding(.top, 12) }
                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if game.finished {
                PlayEndCard(title: endTitle, line: endLine, paid: game.won ? paid : nil,
                            share: share, ink: Self.inkOnOrange) { dismiss() }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Theme.paper)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.finished)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: game.solved)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: game.board)
        .onAppear {
            alreadyBanked = state.playClaimedToday
            if game.guesses.isEmpty, !game.finished,
               let saved = state.playProgress(\.sortPlay, for: game.dealtDay), !saved.isEmpty {
                game.adopt(SortGame(restoring: saved))
            }
        }
    }

    // MARK: - Board

    private var boardArea: some View {
        VStack(spacing: 8) {
            ForEach(game.shownGroups, id: \.self) { g in
                groupBar(g)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
            let rows = stride(from: 0, to: game.board.count, by: 4).map { Array(game.board[$0..<min($0 + 4, game.board.count)]) }
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { w in tile(w) }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func groupBar(_ g: Int) -> some View {
        let group = game.puzzle.groups[g]
        return VStack(spacing: 3) {
            Text(group.name.uppercased())
                .font(Theme.font(11.5, .black)).tracking(1)
                .foregroundStyle(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.8)
            Text(group.words.joined(separator: ", "))
                .font(Theme.font(13.5, .heavy))
                .foregroundStyle(Theme.ink.opacity(0.8))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity).frame(height: 62)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Self.groupFills[g]))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(group.name): \(group.words.joined(separator: ", "))")
    }

    /// Ink and paper (George's pick, 2026-09-10): a solid warm tile, no border,
    /// and a picked tile goes ink and lifts.
    private static let tileFill = Theme.hex(0xEFE8DD)

    private func tile(_ w: Int) -> some View {
        let on = game.selected.contains(w)
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            game.toggle(w)
        } label: {
            Text(game.puzzle.word(w))
                .font(Theme.font(13.5, .black))
                .tracking(-0.2)
                .foregroundStyle(on ? Theme.tabBar : Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity).frame(height: 58)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(on ? Theme.ink : Self.tileFill))
                .shadow(color: Theme.hex(0x2E2622).opacity(on ? 0.18 : 0), radius: 7, y: 5)
                .offset(y: on ? -2 : 0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: on)
        }
        .buttonStyle(PressStyle(scale: 0.95))
        .modifier(Shake(times: on ? shakes : 0))
        .accessibilityLabel(game.puzzle.word(w) + (on ? ", selected" : ""))
    }

    private var foot: some View {
        HStack(spacing: 8) {
            Text("Misses left")
                .font(Theme.font(12.5, .black))
                .foregroundStyle(Theme.muted)
            HStack(spacing: 5) {
                ForEach(0..<SortGame.maxMisses, id: \.self) { i in
                    Circle()
                        .fill(i < game.missesLeft ? Theme.ink : Theme.tileRing)
                        .frame(width: 9, height: 9)
                }
            }
            Spacer()
            Text("\(game.solved.count) of 4")
                .font(Theme.font(12.5, .black))
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.missesLeft) misses left, \(game.solved.count) of 4 groups")
    }

    private var controls: some View {
        HStack(spacing: 10) {
            control("Shuffle", icon: "shuffle") {
                var rng = SystemRandomNumberGenerator()
                game.shuffle(using: &rng)
            }
            control("Clear", icon: "xmark") { game.deselect() }
                .disabled(game.selected.isEmpty)
            Button(action: submit) {
                Text("Submit")
                    .font(Theme.font(14, .black)).foregroundStyle(Theme.tabBar)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(Capsule().fill(game.selected.count == 4 ? Theme.ink : Theme.dim))
            }
            .buttonStyle(PressStyle(scale: 0.97))
            .disabled(game.selected.count != 4)
            .accessibilityLabel("Submit the four selected words")
        }
        .padding(.horizontal, 24)
    }

    private func control(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .black))
                Text(label).font(Theme.font(14, .black))
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity).frame(height: 44)
            .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 2))
            .contentShape(Capsule())
        }
        .buttonStyle(PressStyle(scale: 0.97))
    }

    // MARK: - Copy

    private var kinCopy: String {
        if game.finished { return game.won ? "Four for four." : "Here are the groups." }
        switch game.last {
        case .group(let g): return "\(game.puzzle.groups[g].name). \(4 - game.solved.count) to go."
        case .oneAway: return "One away."
        case .miss: return game.missesLeft == 1 ? "Not a group. Last miss." : "Not a group. \(game.missesLeft) misses left."
        case .repeated: return "Already tried that one."
        case nil:
            if game.selected.count == 4 { return "Four picked. Submit when you're sure." }
            return game.solved.isEmpty ? "Find four that go together." : "Pick the next four."
        }
    }

    private var endTitle: String {
        if game.won { return game.mistakes == 0 ? "Sorted, no misses" : "Sorted" }
        return "Not this time"
    }

    private var endLine: String {
        if game.won { return "\(game.mistakes) miss\(game.mistakes == 1 ? "" : "es"). New board tomorrow." }
        return "\(game.solved.count) of 4 groups. No coins today, and nothing lost. New board tomorrow."
    }

    private var share: String {
        game.won ? "Prepkin Sort \(game.number) · 4 groups · \(game.mistakes) miss\(game.mistakes == 1 ? "" : "es")"
                 : "Prepkin Sort \(game.number) · \(game.solved.count) of 4 groups"
    }

    // MARK: - Input

    private func submit() {
        let outcome = game.submit()
        switch outcome {
        case .group:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .oneAway, .miss:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default) { shakes += 1 }
        case .repeated, nil:
            return
        }
        state.savePlayProgress(\.sortPlay, game.progress, day: game.dealtDay, puzzleRating: game.puzzle.rating)
        if game.finished, game.won, paid == nil {
            paid = state.recordPlaySolve(\.sortPlay, reason: .sort, dealtDay: game.dealtDay)
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

extension SortGame {
    /// Copies a restored round in. Same deal, so only the guesses move.
    func adopt(_ other: SortGame) {
        guard other.puzzle == puzzle else { return }
        board = other.board
        solved = other.solved
        guesses = other.guesses
        finished = other.finished
        won = other.won
        selected = []
        last = nil
    }
}
