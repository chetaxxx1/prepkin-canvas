import SwiftUI

// MARK: - Game model

/// Crossclimb-type ladder. Seven words, each one letter off the next. The middle
/// five come scrambled, each with a clue: type a word and it is checked the
/// moment the fifth letter lands — right locks it green, wrong flashes coral,
/// shakes, and clears so the next try starts clean. Once all five are right, tap
/// two rows to swap them until each is one letter off its neighbour (linked pairs
/// light up); then the top and bottom rungs unlock with their own clues. A hint
/// reveals the next letter, or in the ordering step moves one rung home. Hints
/// are counted, never charged. Timed from the first letter.
@MainActor
final class LadderGame: ObservableObject {
    let puzzle: LadderPuzzle
    let dealtDay: DayKey
    let number: Int
    /// Word indices (1...5) of the middle rows, top to bottom, as currently arranged.
    @Published private(set) var order: [Int]
    /// What has been typed for each of the seven words, by word index.
    @Published private(set) var typed: [String]
    /// The word index being typed into.
    @Published private(set) var selected: Int?
    /// A solved middle row picked up for a swap.
    @Published private(set) var lifted: Int?
    /// The word index whose last check failed. The next key, delete, or the
    /// view's short timer clears the row.
    @Published private(set) var wrong: Int?
    /// Bumped with every wrong check, so a timer only clears the miss it saw.
    private(set) var wrongStamp = 0
    @Published private(set) var hints = 0
    @Published private(set) var finished = false
    @Published private(set) var startedAt: Date?
    /// Flipped on every wrong check so the row can shake.
    @Published private(set) var shake = false
    private(set) var solvedIn: TimeInterval?

    var words: [String] { puzzle.words }
    var clues: [String] { puzzle.clues }
    var top: Int { reversed ? 6 : 0 }
    var bottom: Int { reversed ? 0 : 6 }
    var reversed: Bool { order == [5, 4, 3, 2, 1] }
    var middleDone: Bool { (1...5).allSatisfy(isSolved) }
    /// The middle is right and in a valid order; the end rungs are open.
    var ordered: Bool { middleDone && (order == [1, 2, 3, 4, 5] || reversed) }
    var solvedCount: Int { (0...6).filter(isSolved).count }
    /// Rows on screen, top to bottom, as word indices.
    var rows: [Int] { ordered ? [top] + order + [bottom] : order }

    init(date: Date = Date(), calendar: Calendar = .current, restoring saved: [String]? = nil, startedAt: Date? = nil) {
        number = PlayDeal.number(for: date, calendar: calendar)
        puzzle = PlayDeal.pick(Catalog.ladders, number: number) ?? Catalog.fallbackLadders[0]
        dealtDay = DayKey(date, calendar: calendar)
        order = puzzle.deal
        typed = Array(repeating: "", count: 7)
        self.startedAt = startedAt
        if let saved, saved.count >= 8 {
            let o = saved[0].split(separator: ",").compactMap { Int($0) }
            if Set(o) == Set(1...5) { order = o }
            for i in 0..<7 where saved[i + 1].count <= 5 { typed[i] = saved[i + 1].uppercased() }
            if saved.count > 8, let h = Int(saved[8].dropFirst("hints=".count)) { hints = h }
        }
        finished = (0...6).allSatisfy(isSolved)
        if finished { solvedIn = startedAt.map { Date().timeIntervalSince($0) } ?? 0 }
        else { selected = firstOpen() }
    }

    func isSolved(_ i: Int) -> Bool { typed[i] == words[i] }
    func isMiddle(_ i: Int) -> Bool { (1...5).contains(i) }

    /// The next row that still wants letters, in screen order.
    private func firstOpen(after i: Int? = nil) -> Int? {
        let list = rows
        let start = i.flatMap { list.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
        return (list[start...] + list[..<start]).first { !isSolved($0) }
    }

    func key(_ letter: String, now: Date = Date()) {
        guard !finished, let i = selected, !isSolved(i) else { return }
        // Typing over a miss starts the row again; no need to delete five letters.
        if wrong == i { typed[i] = ""; wrong = nil }
        guard typed[i].count < 5 else { return }
        if startedAt == nil { startedAt = now }
        typed[i] += letter.uppercased()
        check(i, now: now)
    }

    /// A full row is judged at once: right locks it and moves the cursor on,
    /// wrong marks it for the shake and the clear.
    private func check(_ i: Int, now: Date) {
        guard typed[i].count == 5 else { return }
        if typed[i] == words[i] {
            if (0...6).allSatisfy(isSolved) {
                finished = true
                selected = nil
                solvedIn = now.timeIntervalSince(startedAt ?? now)
            } else {
                selected = ordered || !middleDone ? firstOpen(after: i) : nil
            }
        } else {
            wrong = i
            wrongStamp += 1
            shake.toggle()
        }
    }

    func backspace() {
        guard !finished, let i = selected, !isSolved(i), !typed[i].isEmpty else { return }
        if wrong == i { typed[i] = ""; wrong = nil; return }
        typed[i].removeLast()
    }

    /// The view calls this a moment after a miss; a newer miss or a key press
    /// in between means there is nothing left to clear.
    func clearWrong(stamp: Int) {
        guard stamp == wrongStamp, let i = wrong else { return }
        typed[i] = ""
        wrong = nil
    }

    /// Reveals the next letter of the row being typed (wrong letters after it
    /// are dropped), or in the ordering step moves one rung to where it belongs.
    /// Counted on the end card, never charged.
    func hint(now: Date = Date()) {
        guard !finished else { return }
        if startedAt == nil { startedAt = now }
        if middleDone, !ordered {
            // Aim for whichever way up needs fewer moves.
            let up = [1, 2, 3, 4, 5], down = [5, 4, 3, 2, 1]
            let target = zip(order, up).filter { $0 != $1 }.count <= zip(order, down).filter { $0 != $1 }.count ? up : down
            guard let pos = (0..<5).first(where: { order[$0] != target[$0] }),
                  let from = order.firstIndex(of: target[pos]) else { return }
            lifted = nil
            order.swapAt(pos, from)
            hints += 1
            if ordered { selected = top }
            return
        }
        guard let i = selected ?? firstOpen(), !isSolved(i) else { return }
        selected = i
        wrong = nil
        let answer = Array(words[i]), have = Array(typed[i])
        var keep = 0
        while keep < have.count, keep < 5, have[keep] == answer[keep] { keep += 1 }
        typed[i] = String(answer[0...keep])
        hints += 1
        check(i, now: now)
    }

    /// Two rows sit right next to each other on the ladder and are one letter apart.
    func linked(_ a: Int, _ b: Int) -> Bool {
        isSolved(a) && isSolved(b) && zip(words[a], words[b]).filter { $0 != $1 }.count == 1
    }

    /// A tap on a row: pick up a solved middle row to swap it, drop it on another,
    /// or move the cursor to a row that still wants letters.
    func tapRow(_ i: Int) {
        guard !finished else { return }
        if let l = lifted {
            lifted = nil
            guard i != l, isMiddle(i), let a = order.firstIndex(of: l), let b = order.firstIndex(of: i) else { return }
            order.swapAt(a, b)
            if ordered { selected = top }
            return
        }
        if isMiddle(i), isSolved(i), !ordered {
            lifted = i
        } else if !isSolved(i) {
            selected = i
            wrong = nil
        }
    }

    var progress: [String] { [order.map(String.init).joined(separator: ",")] + typed + ["hints=\(hints)"] }

    /// Copies a restored ladder in. Same deal, so only the rows move.
    func adopt(_ other: LadderGame) {
        guard other.puzzle == puzzle else { return }
        order = other.order
        typed = other.typed
        selected = other.selected
        finished = other.finished
        startedAt = other.startedAt
        solvedIn = other.solvedIn
        hints = other.hints
    }
}

// MARK: - Screen

struct LadderView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var game: LadderGame
    @State private var alreadyBanked = false
    @State private var paid: Int?
    @State private var shakeOffset: CGFloat = 0

    private static let mint = Theme.mint
    private static let inkOnMint = Theme.hex(0x0F3D2B)
    private static let eyebrowInk = Theme.hex(0x2E8C68)

    init() {
        _game = StateObject(wrappedValue: LadderGame())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                PlayHeader(fill: Self.mint, ink: Self.inkOnMint, eyebrowInk: Self.eyebrowInk,
                           eyebrow: "LADDER \(game.number) · \(game.solvedCount) OF 7",
                           title: "Ladder", line: "Solve the clues, then order the rungs",
                           banked: alreadyBanked || (paid ?? 0) > 0) { dismiss() }
                PlayKinLine(copy: kinCopy).padding(.top, 14)
                ladder.padding(.top, 12)
                foot.padding(.top, 10)
                Spacer(minLength: 6)
                if !game.finished {
                    PlayKeyboard(onKey: { game.key($0); save() }, onEnter: {}, onDelete: { game.backspace(); save() })
                        .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if game.finished {
                PlayEndCard(title: "Climbed in \(PlayClock.label(game.solvedIn ?? 0))",
                            line: game.hints == 0 ? "No hints. New ladder tomorrow." : "\(game.hints) hint\(game.hints == 1 ? "" : "s"). New ladder tomorrow.",
                            paid: paid, share: share, ink: Self.inkOnMint) { dismiss() }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Theme.paper)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.finished)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: game.order)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: game.ordered)
        .onChange(of: game.shake) { _, _ in
            shakeRow()
            let stamp = game.wrongStamp
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { game.clearWrong(stamp: stamp); save() }
        }
        .onAppear {
            alreadyBanked = state.playClaimedToday
            if game.startedAt == nil, !game.finished,
               let saved = state.playProgress(\.ladderPlay, for: game.dealtDay) {
                game.adopt(LadderGame(restoring: saved, startedAt: state.playStartedAt(\.ladderPlay, for: game.dealtDay)))
            }
        }
    }

    // MARK: - Ladder

    private let side: CGFloat = 40

    private var ladder: some View {
        let rows = game.rows
        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element) { k, i in
                if k > 0 { link(rows[k - 1], i) }
                row(i, above: k > 0 ? rows[k - 1] : nil)
                    .offset(x: game.wrong == i ? shakeOffset : 0)
                    .onTapGesture { game.tapRow(i); save() }
            }
        }
    }

    /// The joint between two rungs. Lit when they are one letter apart, so the
    /// ordering step shows its own progress; faint until then.
    private func link(_ a: Int, _ b: Int) -> some View {
        let on = game.linked(a, b)
        let show = game.middleDone
        return HStack(spacing: 8) {
            Color.clear.frame(width: 24, height: 1)
            Capsule()
                .fill(on ? Theme.mint : Theme.hairline)
                .frame(width: on ? 34 : 22, height: 4)
                .frame(width: side * 5 + 20, height: 8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .opacity(show ? 1 : 0)
        .accessibilityHidden(true)
    }

    private func row(_ i: Int, above: Int?) -> some View {
        let solved = game.isSolved(i)
        let end = !game.isMiddle(i)
        let selected = game.selected == i && !game.finished
        let lifted = game.lifted == i
        let wrong = game.wrong == i
        let letters = Array(game.typed[i])
        // Once the ladder is in order, the letter that changed from the rung
        // above gets the strong fill, so the climb reads top to bottom.
        let previous = (game.ordered && above != nil && game.linked(above!, i)) ? Array(game.words[above!]) : nil
        return HStack(spacing: 8) {
            marker(i, solved: solved, lifted: lifted)
            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { k in
                    let changed = previous.map { k < letters.count && $0[k] != letters[k] } ?? false
                    Text(k < letters.count ? String(letters[k]) : "")
                        .font(Theme.font(side * 0.46, .black))
                        .foregroundStyle(wrong ? Theme.coral : (solved ? (end || changed ? .white : Theme.mintDark) : Theme.ink))
                        .frame(width: side, height: side)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(wrong ? Theme.coralSoft : (solved ? (end ? Theme.ink : (changed ? Theme.mint : Theme.mintSoft)) : Theme.card)))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(ring(solved: solved, selected: selected, lifted: lifted, wrong: wrong),
                                          lineWidth: selected || lifted || wrong ? 2 : 1.5))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .scaleEffect(lifted ? 1.03 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility(i, solved: solved, end: end))
        .accessibilityAddTraits(.isButton)
    }

    private func ring(solved: Bool, selected: Bool, lifted: Bool, wrong: Bool) -> Color {
        if wrong { return Theme.coral }
        if lifted { return Theme.coin }
        if selected { return Theme.ink }
        return solved ? .clear : Theme.tileRing
    }

    /// The badge at the left of a row: a lock on an end rung, a grip on a solved
    /// middle row that can be picked up, a dot on a row still wanting letters.
    @ViewBuilder private func marker(_ i: Int, solved: Bool, lifted: Bool) -> some View {
        let end = !game.isMiddle(i)
        ZStack {
            Circle().fill(lifted ? Theme.coinSoft : Theme.tile)
            if end {
                Image(systemName: solved ? "checkmark" : "lock.open.fill")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Theme.muted)
            } else if solved, !game.ordered {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(lifted ? Theme.coinDark : Theme.muted)
            } else if solved {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Theme.mintDark)
            } else {
                Circle().fill(Theme.muted).frame(width: 6, height: 6)
            }
        }
        .frame(width: 24, height: 24)
    }

    private func accessibility(_ i: Int, solved: Bool, end: Bool) -> String {
        let place = end ? (i == game.top ? "Top rung" : "Bottom rung") : "Rung"
        if solved { return "\(place) \(game.words[i]), solved" }
        let typed = game.typed[i].isEmpty ? "empty" : "typed \(game.typed[i])"
        return "\(place), clue: \(game.clues[i]), \(typed)"
    }

    private var foot: some View {
        HStack(spacing: 10) {
            Text(footCopy)
                .font(Theme.font(12.5, .black))
                .foregroundStyle(Theme.muted)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            if !game.finished { hintButton }
            PlayStopwatch(since: game.startedAt, frozen: game.solvedIn)
        }
        .padding(.horizontal, 28)
    }

    /// Reveals a letter, or moves a rung home. Free, counted on the end card.
    private var hintButton: some View {
        Button {
            game.hint()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            save()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill").font(.system(size: 10.5, weight: .black))
                Text(game.hints == 0 ? "Hint" : "Hint · \(game.hints)").font(Theme.font(12, .black))
            }
            .foregroundStyle(Theme.coinDark)
            .padding(.horizontal, 11).frame(height: 30)
            .background(Capsule().fill(Theme.coinSoft))
        }
        .buttonStyle(PressStyle(scale: 0.95))
        .accessibilityLabel(game.middleDone && !game.ordered ? "Hint: move one rung into place" : "Hint: reveal the next letter")
    }

    private var footCopy: String {
        if game.finished { return game.hints == 0 ? "All seven, no hints." : "All seven." }
        if game.ordered { return "Middle set. Two to go." }
        if game.middleDone {
            let links = zip(game.order, game.order.dropFirst()).filter { game.linked($0, $1) }.count
            return game.lifted == nil ? "\(links) of 4 linked · tap a rung" : "Tap where it goes"
        }
        return "\(game.solvedCount) of 7"
    }

    // MARK: - Copy

    /// The kin reads out the clue for the row being typed; between phases it
    /// says what to do next. Never a hint at the answer.
    private var kinCopy: String {
        if game.finished { return "Top to bottom, one letter a rung." }
        if let w = game.wrong { return "Not \(game.typed[w]). Try again." }
        if game.middleDone, !game.ordered {
            return game.lifted == nil ? "Now order them. Linked pairs light up." : "Drop it on the rung to swap with."
        }
        if let i = game.selected { return "“\(game.clues[i])”" }
        return "Tap a rung to type."
    }

    private var share: String {
        let hints = game.hints == 0 ? "no hints" : "\(game.hints) hint\(game.hints == 1 ? "" : "s")"
        return "Prepkin Ladder \(game.number) · \(PlayClock.label(game.solvedIn ?? 0)) · \(hints)"
    }

    // MARK: - State

    private func save() {
        state.savePlayProgress(\.ladderPlay, game.progress, startedAt: game.startedAt, day: game.dealtDay,
                               puzzleRating: game.puzzle.rating)
        if game.finished, paid == nil {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            paid = state.recordPlaySolve(\.ladderPlay, reason: .ladder, dealtDay: game.dealtDay)
        } else if game.wrong != nil {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func shakeRow() {
        guard !reduceMotion else { return }
        let steps: [CGFloat] = [-8, 8, -6, 6, -3, 0]
        for (i, dx) in steps.enumerated() {
            withAnimation(.linear(duration: 0.05).delay(Double(i) * 0.05)) { shakeOffset = dx }
        }
    }
}
