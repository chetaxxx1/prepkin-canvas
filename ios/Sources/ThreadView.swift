import SwiftUI

// MARK: - Game model

/// Five clues that share one link, hardest first. Name the link in as few clues
/// as you can; a miss turns over the next one. Miss all five and the answer is
/// shown, no coins, nothing lost.
@MainActor
final class ThreadGame: ObservableObject {
    let puzzle: ThreadPuzzle
    let dealtDay: DayKey
    let number: Int
    @Published private(set) var misses: [String] = []
    /// The last miss shared a word with the answer: close, but not it.
    @Published private(set) var lastWasClose = false
    @Published private(set) var finished = false
    /// Which clue it was got on, 1–5. Zero for a miss.
    @Published private(set) var got = 0

    var shown: Int { min(5, misses.count + 1) }

    init(date: Date = Date(), calendar: Calendar = .current, restoring saved: [String] = [], solved: Bool = false) {
        number = PlayDeal.number(for: date, calendar: calendar)
        puzzle = PlayDeal.pick(Catalog.threads, number: number)
            ?? ThreadPuzzle(id: "card", name: "___ card", accept: ["card"],
                            clues: ["Wild", "Green", "Report", "Business", "Credit"])
        dealtDay = DayKey(date, calendar: calendar)
        misses = Array(saved.prefix(5))
        if solved {
            finished = true
            got = min(5, misses.count + 1)
        } else if misses.count >= 5 {
            finished = true
        }
    }

    /// Filler that never decides a match: "things that are due" and "due" are the
    /// same answer.
    private static let filler: Set<String> = [
        "the", "a", "an", "things", "thing", "that", "you", "can", "kinds", "kind", "of", "types", "type",
        "words", "word", "before", "after", "with", "are", "is", "they", "all", "have", "has", "it", "its",
        "stuff", "something", "someone", "people", "who", "be", "i", "think", "maybe", "for", "to", "and",
    ]

    static func tokens(_ s: String) -> [String] {
        let cleaned: [Character] = s.lowercased().map { c in (c.isLetter || c.isNumber) ? c : " " }
        let words: [String] = cleaned.split(separator: " ").map { String($0) }
        var out: [String] = []
        for w in words where !filler.contains(w) {
            out.append(w.count > 3 && w.hasSuffix("s") ? String(w.dropLast()) : w)
        }
        return out
    }

    /// A guess counts when it carries every token of some accepted answer.
    static func matches(_ guess: String, _ puzzle: ThreadPuzzle) -> Bool {
        let g = tokens(guess)
        guard !g.isEmpty else { return false }
        return puzzle.accept.contains { accept in
            let a = tokens(accept)
            return !a.isEmpty && a.allSatisfy { g.contains($0) }
        }
    }

    /// True on a hit. A miss records the guess and turns the next clue.
    @discardableResult
    func guess(_ text: String) -> Bool {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finished, !text.isEmpty else { return false }
        if Self.matches(text, puzzle) {
            got = shown
            finished = true
            return true
        }
        lastWasClose = Self.isClose(text, puzzle)
        misses.append(text)
        if misses.count >= 5 { finished = true }
        return false
    }

    /// A miss that shares a real word with an accepted answer ("card games" for
    /// "___ card"). Still a miss, but the kin says so.
    static func isClose(_ guess: String, _ puzzle: ThreadPuzzle) -> Bool {
        let g = Set(tokens(guess))
        return !g.isEmpty && puzzle.accept.contains { !g.isDisjoint(with: tokens($0)) }
    }
}

// MARK: - Screen

struct ThreadView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var game: ThreadGame
    @State private var alreadyBanked = false
    @State private var paid: Int?
    @State private var text = ""
    @FocusState private var typing: Bool

    private static let pink = Theme.hex(0xF7A8B8)
    private static let inkOnPink = Theme.hex(0x5A1F2E)
    private static let eyebrowInk = Theme.hex(0xB0475F)

    init() {
        _game = StateObject(wrappedValue: ThreadGame())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                PlayHeader(fill: Self.pink, ink: Self.inkOnPink, eyebrowInk: Self.eyebrowInk,
                           eyebrow: "THREAD \(game.number) · CLUE \(game.shown) OF 5",
                           title: "Thread", line: "Five clues, one link",
                           banked: alreadyBanked || (paid ?? 0) > 0) { dismiss() }
                PlayKinLine(copy: kinCopy).padding(.top, 14)
                clues.padding(.top, 16)
                if !game.finished {
                    guessRow.padding(.top, 14)
                }
                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if game.finished {
                PlayEndCard(title: endTitle, line: endLine, paid: game.got > 0 ? paid : nil,
                            share: share, ink: Self.inkOnPink) { dismiss() }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Theme.paper)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.finished)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: game.shown)
        .onAppear {
            alreadyBanked = state.playClaimedToday
            if game.misses.isEmpty, !game.finished {
                let saved = state.playProgress(\.threadPlay, for: game.dealtDay) ?? []
                let solved = state.game.threadPlay.lastDay == game.dealtDay
                if !saved.isEmpty || solved { game.adopt(ThreadGame(restoring: saved, solved: solved)) }
            }
            if !game.finished { typing = true }
        }
    }

    // MARK: - Clues

    private var clues: some View {
        VStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { i in
                let open = i < game.shown || game.finished
                HStack(spacing: 12) {
                    Text("\(i + 1)")
                        .font(Theme.font(12, .black))
                        .foregroundStyle(open ? Theme.muted : Theme.dim)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(open ? Theme.tile : .clear))
                    Text(open ? game.puzzle.clues[i] : "")
                        .font(Theme.font(17, .black))
                        .tracking(-0.2)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 6)
                    // The guess made on this clue, struck through, so the misses
                    // sit where they happened instead of in a list underneath.
                    if i < game.misses.count {
                        Text(game.misses[i])
                            .font(Theme.font(12.5, .heavy))
                            .strikethrough(true, color: Theme.coral)
                            .foregroundStyle(Theme.coral)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: 120, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(open ? Theme.card : .clear))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(open ? Theme.hairline : Theme.tileRing, lineWidth: 1.5))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel((open ? "Clue \(i + 1): \(game.puzzle.clues[i])" : "Clue \(i + 1), not yet shown")
                                    + (i < game.misses.count ? ", guessed \(game.misses[i]), not it" : ""))
            }
        }
        .padding(.horizontal, 20)
    }

    private var guessRow: some View {
        HStack(spacing: 8) {
            TextField("What do they share?", text: $text)
                .font(Theme.font(15, .heavy))
                .foregroundStyle(Theme.ink)
                .focused($typing)
                .submitLabel(.go)
                .autocorrectionDisabled()
                .onSubmit(submit)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(typing ? Theme.ink : Theme.tileRing, lineWidth: typing ? 2 : 1.5))
            Button(action: submit) {
                Text("Guess")
                    .font(Theme.font(14.5, .black)).foregroundStyle(.white)
                    .padding(.horizontal, 18).frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Copy

    private var kinCopy: String {
        if game.finished { return game.got > 0 ? "Fewer clues, better. That's \(game.got)." : "It was \(game.puzzle.name)." }
        if game.lastWasClose, game.shown > 1 { return "Close. Be more specific." }
        switch game.shown {
        case 1: return "One clue. Take a swing."
        case 5: return "Last clue. This one's the giveaway."
        default: return "Not \(game.misses.last ?? "that"). Here's another."
        }
    }

    private var endTitle: String {
        switch game.got {
        case 0: return "It was: \(game.puzzle.name)"
        case 1: return "First clue. Sharp."
        default: return "Got it on clue \(game.got)"
        }
    }

    private var endLine: String {
        if game.got == 0 { return "No coins today, and nothing lost. New thread tomorrow." }
        return "The link was \(game.puzzle.name). New thread tomorrow."
    }

    private var share: String {
        game.got > 0 ? "Prepkin Thread \(game.number) · clue \(game.got) of 5"
                     : "Prepkin Thread \(game.number) · missed"
    }

    // MARK: - Input

    private func submit() {
        let guess = text
        guard !guess.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        text = ""
        if game.guess(guess) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            typing = false
            state.savePlayProgress(\.threadPlay, game.misses, day: game.dealtDay,
                                   puzzleRating: game.puzzle.rating)
            paid = state.recordPlaySolve(\.threadPlay, reason: .thread, dealtDay: game.dealtDay)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            state.savePlayProgress(\.threadPlay, game.misses, day: game.dealtDay,
                                   puzzleRating: game.puzzle.rating)
            if game.finished { typing = false }
        }
    }
}

extension ThreadGame {
    /// Copies a restored round in. Same deal, so only the misses move.
    func adopt(_ other: ThreadGame) {
        guard other.puzzle == puzzle else { return }
        misses = other.misses
        finished = other.finished
        got = other.got
    }
}
