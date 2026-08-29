import SwiftUI

// MARK: - Game model

@MainActor
final class WordleGame: ObservableObject {
    static let answers = [
        "ABOUT", "BRAVE", "CHILL", "DREAM", "EARLY", "FOCUS", "GRIND", "HONOR",
        "IDEAS", "JUICE", "KNACK", "LEARN", "MONEY", "NOTES", "OCEAN", "PRIDE",
        "QUIET", "SLIME", "STUDY", "THINK", "ULTRA", "VIVID", "WORTH", "YOUTH",
        "SMART", "POINT", "COACH", "TRACK", "SPARK", "BLOOM",
    ]

    enum TileState { case empty, absent, present, correct }

    let target: String
    @Published var guesses: [String] = []
    @Published var current = ""
    @Published var finished = false
    @Published var won = false
    @Published var shake = false

    init(date: Date = Date()) {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        target = Self.answers[day % Self.answers.count]
    }

    func key(_ letter: String) {
        guard !finished, current.count < 5 else { return }
        current += letter
    }

    func backspace() {
        guard !finished, !current.isEmpty else { return }
        current.removeLast()
    }

    func submit(onWin: (Int) -> Void) {
        guard !finished else { return }
        guard current.count == 5 else {
            shake.toggle()
            return
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

struct WordleView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var game = WordleGame()
    @AppStorage("wordleRewardDay") private var rewardDay = ""

    var body: some View {
        VStack(spacing: 16) {
            grid
            if game.finished {
                Text(game.won ? "Solved in \(game.guesses.count)! +30 coins" : "Out of guesses — it was \(game.target)")
                    .font(.headline)
                    .foregroundStyle(game.won ? Theme.mint : Theme.coral)
            }
            Spacer(minLength: 0)
            keyboard
        }
        .padding(16)
        .background(Theme.paper)
        .navigationTitle("Daily Word")
        .hidesTabBar()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var grid: some View {
        VStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { col in
                        tile(row: row, col: col)
                    }
                }
            }
        }
        .phaseAnimator([0, 1], trigger: game.shake) { view, _ in view }
    }

    private func tile(row: Int, col: Int) -> some View {
        let (letter, tileState): (String, WordleGame.TileState) = {
            if row < game.guesses.count {
                let guess = game.guesses[row]
                let ch = String(Array(guess)[col])
                return (ch, game.states(for: guess)[col])
            }
            if row == game.guesses.count, col < game.current.count {
                return (String(Array(game.current)[col]), .empty)
            }
            return ("", .empty)
        }()

        return Text(letter)
            .font(.title2.bold())
            .foregroundStyle(tileState == .empty ? Theme.ink : .white)
            .frame(width: 54, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color(tileState))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(tileState == .empty ? Theme.muted.opacity(0.3) : .clear, lineWidth: 1.5)
            )
    }

    private func color(_ s: WordleGame.TileState) -> Color {
        switch s {
        case .empty: return Theme.card
        case .absent: return Theme.muted.opacity(0.55)
        case .present: return Theme.sun
        case .correct: return Theme.mint
        }
    }

    private var keyboard: some View {
        VStack(spacing: 6) {
            keyRow("QWERTYUIOP")
            keyRow("ASDFGHJKL")
            HStack(spacing: 5) {
                wideKey("GO") { game.submit(onWin: rewardWin) }
                keyRow("ZXCVBNM", spacing: 0)
                wideKey("⌫") { game.backspace() }
            }
        }
    }

    private func keyRow(_ letters: String, spacing: CGFloat = 5) -> some View {
        HStack(spacing: 5) {
            ForEach(letters.map(String.init), id: \.self) { letter in
                Button { game.key(letter) } label: {
                    Text(letter)
                        .font(.subheadline.bold())
                        .foregroundStyle(game.keyboardState(letter) == .empty ? Theme.ink : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(RoundedRectangle(cornerRadius: 7).fill(keyColor(letter)))
                }
            }
        }
    }

    private func keyColor(_ letter: String) -> Color {
        let s = game.keyboardState(letter)
        return s == .empty ? Theme.card : color(s)
    }

    private func wideKey(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(Theme.ink)
                .frame(width: 50, height: 46)
                .background(RoundedRectangle(cornerRadius: 7).fill(Theme.card))
        }
    }

    private func rewardWin(guesses: Int) {
        let today = Date().formatted(.iso8601.year().month().day())
        guard rewardDay != today else { return }
        rewardDay = today
        state.recordWordleWin(guesses: guesses)
    }
}
