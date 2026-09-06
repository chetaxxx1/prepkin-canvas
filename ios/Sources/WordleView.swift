import SwiftUI

// MARK: - Game model

@MainActor
final class WordleGame: ObservableObject {
    /// Word list lives in Resources/Content/words.json.
    static var answers: [String] { Catalog.wordleAnswers }
    /// The much wider list of words a guess is allowed to be, from guesses.json.
    static var allowedGuesses: Set<String> { Catalog.wordleGuesses }

    enum TileState { case empty, absent, present, correct }

    /// Why a submit did or didn't land. The board shakes on both refusals, but only
    /// a real word costs a try.
    enum Submission { case accepted, tooShort, notAWord }

    let target: String
    @Published var guesses: [String] = []
    @Published var current = ""
    @Published var finished = false
    @Published var won = false
    @Published var shake = false

    /// The day this puzzle was dealt. The win is paid under this key, so a solve
    /// finished just past midnight cannot double-dip into tomorrow's word.
    let dealtDay: DayKey

    init(date: Date = Date(), restoring saved: [String] = []) {
        target = Self.answer(for: date)
        dealtDay = DayKey(date)
        restore(saved)
    }

    static func answer(for date: Date = Date()) -> String {
        let words = answers
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return words.isEmpty ? "SLIME" : words[day % words.count]
    }

    /// Counts up one a day from the first word, for the "WORD 214" eyebrow.
    static func puzzleNumber(for date: Date = Date(), calendar: Calendar = .current) -> Int {
        let first = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? date
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: first),
                                           to: calendar.startOfDay(for: date)).day ?? 0
        return max(1, days + 1)
    }

    /// Puts a saved board back, so leaving mid-puzzle keeps the guesses and a
    /// solved board stays solved.
    private func restore(_ saved: [String]) {
        guesses = saved.filter { $0.count == 5 }
        if guesses.last == target {
            finished = true
            won = true
        } else if guesses.count >= 6 {
            finished = true
        }
    }

    var triesLeft: Int { 6 - guesses.count }

    func key(_ letter: String) {
        guard !finished, current.count < 5 else { return }
        current += letter
    }

    func backspace() {
        guard !finished, !current.isEmpty else { return }
        current.removeLast()
    }

    /// A guess only costs a try when it's five letters *and* a word on the list.
    @discardableResult
    func submit(onWin: (Int) -> Void) -> Submission {
        guard !finished else { return .tooShort }
        guard current.count == 5 else {
            shake.toggle()
            return .tooShort
        }
        guard Self.allowedGuesses.contains(current) else {
            shake.toggle()
            return .notAWord
        }
        guesses.append(current)
        if current == target {
            finished = true
            won = true
            onWin(guesses.count)
        } else if guesses.count == 6 {
            finished = true
        }
        current = ""
        return .accepted
    }

    /// Wordle coloring with duplicate-letter handling.
    func states(for guess: String) -> [TileState] {
        let g = Array(guess), t = Array(target)
        var result = [TileState](repeating: .absent, count: 5)
        var remaining: [Character: Int] = [:]
        for i in 0..<5 where g[i] != t[i] {
            remaining[t[i], default: 0] += 1
        }
        for i in 0..<5 {
            if g[i] == t[i] {
                result[i] = .correct
            } else if remaining[g[i], default: 0] > 0 {
                result[i] = .present
                remaining[g[i]]! -= 1
            }
        }
        return result
    }

    func keyboardState(_ letter: String) -> TileState {
        var best = TileState.empty
        for guess in guesses {
            let st = states(for: guess)
            for (i, ch) in guess.enumerated() where String(ch) == letter {
                switch st[i] {
                case .correct: return .correct
                case .present: best = .present
                case .absent: if best == .empty { best = .absent }
                default: break
                }
            }
        }
        return best
    }
}

// MARK: - View

/// The board. Same butter-and-cream language as the Games tab it opens from: the
/// header is a short butter band with the puzzle number and the reward, the tiles
/// sit on cream, the keyboard is white keys, and the end of the game is a card that
/// rises over the keyboard rather than a line of text squeezed above it.
///
/// References: NYT Wordle (tile states), Abode's Word Guess (attempt counter in the
/// header, confetti on the solve, big rounded keys).
struct WordleView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var game: WordleGame
    /// Read once, before the win is posted, so the message tells the truth.
    @State private var alreadyClaimed = false
    @State private var shakeOffset: CGFloat = 0
    @State private var wrongGuess = 0
    /// Bumped on every rejected guess. The bubble reads off it so two bad words in a
    /// row restart the 1.5 s rather than the second one inheriting the first's timer.
    @State private var notAWord = 0

    private static let butter = Theme.hex(0xFFC94D)
    private static let inkOnButter = Theme.hex(0x3A2A05)
    private static let eyebrowInk = Theme.hex(0x7A5C1E)
    private static let absent = Theme.hex(0xC9BEAC)

    init() {
        _game = StateObject(wrappedValue: WordleGame())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                kinLine.padding(.top, 14)
                grid.padding(.top, 16)
                Spacer(minLength: 8)
                keyboard.padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if game.finished { endCard.transition(.move(edge: .bottom).combined(with: .opacity)) }
        }
        .background(Theme.paper)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.finished)
        .onAppear {
            alreadyClaimed = state.wordleClaimedToday
            let saved = state.wordleGuesses(for: game.dealtDay)
            if !saved.isEmpty && game.guesses.isEmpty {
                // Restored on first appearance only. `init` cannot see `state`.
                for g in saved { game.current = g; _ = game.submit(onWin: { _ in }) }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack(alignment: .top) {
            Self.butter
            VStack(spacing: 10) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Self.inkOnButter)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Theme.card))
                    }
                    .accessibilityLabel("Back to Games")
                    Spacer()
                    Text("WORD \(WordleGame.puzzleNumber()) · \(triesLine)")
                        .font(Theme.font(10.5, .black))
                        .tracking(1.5)
                        .foregroundStyle(Self.eyebrowInk)
                        .padding(.horizontal, 13).padding(.vertical, 6)
                        .background(Capsule().fill(Theme.card))
                    Spacer()
                    rewardChip
                }
                Text("Daily Word")
                    .font(Theme.font(28, .black))
                    .tracking(-0.9)
                    .foregroundStyle(Self.inkOnButter)
            }
            .padding(.horizontal, 20)
            .padding(.top, 64)
        }
        .frame(height: 168)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30,
                                          style: .continuous))
    }

    private var triesLine: String {
        if game.won { return "SOLVED IN \(game.guesses.count)" }
        if game.finished { return "OUT OF TRIES" }
        return "GUESS \(min(game.guesses.count + 1, 6)) OF 6"
    }

    private var rewardChip: some View {
        HStack(spacing: 5) {
            CoinDisc(size: 13)
            Text(alreadyClaimed || game.won ? "30" : "+30")
                .font(Theme.font(13, .black))
                .foregroundStyle(Self.inkOnButter)
        }
        .padding(.horizontal, 11).padding(.vertical, 7)
        .background(Capsule().fill(Theme.card))
        .opacity(alreadyClaimed || game.won ? 0.6 : 1)
        .accessibilityLabel(alreadyClaimed ? "Today's 30 coins already banked" : "30 coins for solving")
    }

    /// Kin reacts to the board: a nudge before the first guess, the count after a
    /// miss, the answer when the tries run out.
    private var kinLine: some View {
        HStack(spacing: 9) {
            SproutFace(speciesID: state.activeChibiID, size: 34,
                       plate: Theme.species(state.activeChibiID).opacity(0.35))
            Text(kinCopy)
                .font(Theme.font(13.5, .heavy))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card))
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var kinCopy: String {
        if notAWord > 0 { return "Not in the word list." }
        if game.won { return game.guesses.count <= 2 ? "Show-off." : "Knew you'd get it." }
        if game.finished { return "It was \(game.target). Tomorrow's is kinder." }
        switch game.guesses.count {
        case 0: return "Five letters. Start with vowels."
        case 1: return "Mint means right spot. Gold means wrong spot."
        case 5: return "Last one. Take your time."
        default: return "Not that one. \(game.triesLeft) tries left."
        }
    }

    // MARK: - Grid

    private var grid: some View {
        VStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { col in tile(row: row, col: col) }
                }
                .offset(x: row == game.guesses.count ? shakeOffset : 0)
            }
        }
        .onChange(of: game.shake) { _, _ in shakeRow() }
    }

    private func tile(row: Int, col: Int) -> some View {
        let (letter, tileState): (String, WordleGame.TileState) = {
            if row < game.guesses.count {
                let guess = game.guesses[row]
                return (String(Array(guess)[col]), game.states(for: guess)[col])
            }
            if row == game.guesses.count, col < game.current.count {
                return (String(Array(game.current)[col]), .empty)
            }
            return ("", .empty)
        }()
        let filled = tileState != .empty
        return Text(letter)
            .font(Theme.font(24, .black))
            .foregroundStyle(filled ? .white : Theme.ink)
            .frame(width: 56, height: 56)
            .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(color(tileState)))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(filled ? .clear : (letter.isEmpty ? Theme.hairline : Theme.ink.opacity(0.35)),
                              lineWidth: 2))
            .scaleEffect(letter.isEmpty || filled ? 1 : 1.05)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: letter)
    }

    private func color(_ s: WordleGame.TileState) -> Color {
        switch s {
        case .empty: return Theme.card
        case .absent: return Self.absent
        case .present: return Theme.coin
        case .correct: return Theme.mint
        }
    }

    private func shakeRow() {
        guard !reduceMotion else { return }
        let steps: [CGFloat] = [-8, 8, -6, 6, -3, 0]
        for (i, dx) in steps.enumerated() {
            withAnimation(.linear(duration: 0.05).delay(Double(i) * 0.05)) { shakeOffset = dx }
        }
    }

    // MARK: - Keyboard

    private var keyboard: some View {
        VStack(spacing: 7) {
            keyRow("QWERTYUIOP")
            keyRow("ASDFGHJKL").padding(.horizontal, 18)
            HStack(spacing: 5) {
                wideKey(label: "Enter", icon: nil) { submit() }
                keyRow("ZXCVBNM")
                wideKey(label: nil, icon: "delete.left.fill") { game.backspace() }
            }
        }
        .padding(.horizontal, 6)
    }

    private func keyRow(_ letters: String) -> some View {
        HStack(spacing: 5) {
            ForEach(letters.map(String.init), id: \.self) { letter in
                Button { game.key(letter) } label: {
                    Text(letter)
                        .font(Theme.font(16, .heavy))
                        .foregroundStyle(keyInk(letter))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(keyColor(letter))
                            .shadow(color: Theme.hex(0x2E2822).opacity(0.06), radius: 2, y: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func keyInk(_ letter: String) -> Color {
        game.keyboardState(letter) == .empty ? Theme.ink : .white
    }

    private func keyColor(_ letter: String) -> Color {
        let s = game.keyboardState(letter)
        return s == .empty ? Theme.card : color(s)
    }

    private func wideKey(label: String?, icon: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let label {
                    Text(label).font(Theme.font(13.5, .black)).foregroundStyle(Theme.coralDeep)
                } else if let icon {
                    Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.ink)
                }
            }
            .frame(width: 54, height: 50)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.hex(0x2E2822).opacity(0.06), radius: 2, y: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label ?? "Delete")
    }

    private func submit() {
        switch game.submit(onWin: rewardWin) {
        case .tooShort:
            return
        case .notAWord:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            notAWord += 1
            let shown = notAWord
            // Clears itself, and only if no newer refusal has taken over the bubble.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if notAWord == shown { notAWord = 0 }
            }
        case .accepted:
            notAWord = 0
            state.saveWordleGuesses(game.guesses, for: game.dealtDay)
            UIImpactFeedbackGenerator(style: game.finished ? .medium : .light).impactOccurred()
        }
    }

    /// No day stamp to keep here — the ledger's `wordle:<day>` key is what makes
    /// this pay once, and it can't be reset by changing the device clock.
    private func rewardWin(guesses: Int) {
        state.recordWordleWin(guesses: guesses, dealtDay: game.dealtDay)
    }

    // MARK: - End card

    /// Rises over the keyboard. A solve keeps the mint tiles in view above it;
    /// running out shows the word rather than a consolation.
    private var endCard: some View {
        VStack(spacing: 10) {
            SproutImage(speciesID: state.activeChibiID,
                        level: state.activeChibi.level,
                        skin: state.activeChibi.skinID,
                        animation: game.won ? .celebrate : .slump,
                        size: 120)
            Text(game.won ? "Solved in \(game.guesses.count)." : "It was \(game.target).")
                .font(Theme.font(24, .black))
                .foregroundStyle(Theme.ink)
            Text(endLine)
                .font(Theme.font(13.5, .bold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            if game.won {
                HStack(spacing: 6) {
                    CoinDisc(size: 15)
                    Text(alreadyClaimed ? "Today's 30 already banked" : "+30 coins banked")
                        .font(Theme.font(13.5, .heavy)).foregroundStyle(Theme.coinDark)
                }
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(Capsule().fill(Theme.coinSoft))
            }
            Button { dismiss() } label: {
                Text("Back to Games")
                    .font(Theme.font(16.5, .black)).foregroundStyle(Self.inkOnButter)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
            .padding(.top, 6)
        }
        .padding(.horizontal, 22).padding(.top, 22).padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.hex(0x2E2822).opacity(0.14), radius: 24, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var endLine: String {
        if game.won {
            let streak = state.wordleStreak
            return streak > 1 ? "\(streak) days in a row. New word tomorrow." : "New word tomorrow."
        }
        return "No coins today, and nothing lost. New word tomorrow."
    }
}
