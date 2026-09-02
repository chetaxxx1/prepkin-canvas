import SwiftUI

/// Games, per `design_handoff_prepkin_games_tab` (design 38a).
///
/// One job: into today's Daily Word in one tap, with the habit's worth (streak,
/// solved, best) right under it, and the games that are not live yet shown as
/// something coming rather than dead rows. The butter field belongs to the daily
/// ritual; every other game is a card on the rail.
///
/// Deviations from the handoff, on purpose:
/// - The bottom nav is the app's own tab bar, not the dark pill the mock draws.
///   The handoff itself says to use the codebase's components.
/// - The mascot is Sprout in the equipped coat, not the slime in the mock.
/// - "See all" is dropped: there are three games, and they are all on the rail.
/// - Locked cards say what unlocks them, but a bar only appears where there is a
///   real number to fill it with (coins). No made-up progress.
struct GamesView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var playing = false
    @State private var playingNumberLine = false
    @State private var locked: GameCard?
    @State private var caretOn = true

    // Tokens from the handoff.
    private static let butter = Theme.hex(0xFFC94D)
    private static let disc = Theme.hex(0xFFD470)
    private static let inkOnButter = Theme.hex(0x3A2A05)
    private static let inkMuted = Theme.hex(0x6E6357)
    private static let eyebrowInk = Theme.hex(0x7A5C1E)
    private static let coralShadow = Theme.hex(0xE15546)
    private static let coralDeep = Theme.hex(0xC6432F)

    private var solvedToday: Bool { state.wordleClaimedToday }
    private var todaysGuesses: [String] { state.wordleGuesses(for: state.game.effectiveDay) }
    private var outOfTries: Bool { !solvedToday && todaysGuesses.count >= 6 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    field
                    statChips.padding(.top, -16)
                    cta.padding(.top, 10)
                    railHeader.padding(.top, 14)
                    rail.padding(.top, 9)
                }
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .background(Theme.paper)
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $playing) { WordleView() }
            .navigationDestination(isPresented: $playingNumberLine) { NumberLineView() }
        }
        .sheet(item: $locked) { card in
            LockedGameSheet(card: card, coins: state.coins)
                .presentationDetents([.fraction(0.42)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            guard !reduceMotion else { return }
            // The caret is a hard blink, not a fade.
            Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { _ in caretOn.toggle() }
        }
    }

    // MARK: - Field

    private var field: some View {
        ZStack(alignment: .top) {
            Self.butter
            Circle().fill(Self.disc).frame(width: 286, height: 286).padding(.top, 132)
            Circle().fill(.white.opacity(0.22)).frame(width: 132, height: 132)
                .offset(x: -195 + 20, y: 266)
                .frame(maxWidth: .infinity, alignment: .leading)
            sparkles

            VStack(spacing: 0) {
                header
                kinLine.padding(.top, 12).padding(.horizontal, 24)
                mascot.padding(.top, 2)
                tileRow.padding(.top, 10)
                eyebrow.padding(.top, 12)
                Text("Daily Word")
                    .font(Theme.font(32, .black))
                    .tracking(-1.1)
                    .foregroundStyle(Self.inkOnButter)
                    .padding(.top, 6)
            }
        }
        .frame(height: 446 + 10)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 38, bottomTrailingRadius: 38,
                                          style: .continuous))
    }

    @ViewBuilder private var sparkles: some View {
        if !reduceMotion {
            Sparkle(shape: .square, color: Theme.coral, size: 11)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 22).padding(.top, 246)
            Sparkle(shape: .dot, color: .white, size: 9, delay: 1.1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 26).padding(.top, 212)
        }
    }

    private var header: some View {
        HStack {
            Text("Games")
                .font(Theme.font(28, .black))
                .tracking(-0.9)
                .foregroundStyle(Self.inkOnButter)
            Spacer()
            CoinBadge(coins: state.coins)
        }
        .padding(.horizontal, 24)
        .padding(.top, 64)
    }

    /// Kin's line. Above the mascot with the tail pointing down — never over him.
    private var kinLine: some View {
        VStack(spacing: 0) {
            Text(kinCopy)
                .font(Theme.font(13, .heavy))
                .foregroundStyle(Self.inkOnButter)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: Theme.hex(0x7A5000).opacity(0.16), radius: 5, y: 3))
            Triangle().fill(Theme.card).frame(width: 16, height: 9)
        }
    }

    private static let lines = [
        "Five letters. I think you'll get it in four.",
        "Start with a word full of vowels. Trust me.",
        "I already know today's word. Not telling.",
        "Six tries. You usually only need four.",
        "Today's one is good. Go on.",
    ]

    private var kinCopy: String {
        if solvedToday, let n = todaysGuesses.count as Int?, n > 0 {
            return n == 1 ? "First try. Show-off." : "Solved in \(n). Same time tomorrow?"
        }
        if outOfTries { return "That was a hard one. Tomorrow's is kinder." }
        let seed = state.game.effectiveDay.raw.hashValue
        return Self.lines[abs(seed) % Self.lines.count]
    }

    private var mascot: some View {
        ZStack(alignment: .bottom) {
            Ellipse().fill(Theme.hex(0x7A5000).opacity(0.16)).frame(width: 180, height: 28)
                .padding(.bottom, 2)
            SproutImage(speciesID: state.activeChibiID,
                        level: state.activeChibi.level,
                        animation: state.animation,
                        size: 150)
                .modifier(Bob(enabled: !reduceMotion))
        }
    }

    /// The game's own object. Unplayed: an empty row with a blinking caret. Solved:
    /// the word itself in mint. Tapping it opens the board like the button does.
    private var tileRow: some View {
        let letters = solvedToday ? Array(todaysGuesses.last ?? "") : []
        return Button { playing = true } label: {
            HStack(spacing: 7) {
                ForEach(0..<5, id: \.self) { i in
                    ZStack {
                        if i < letters.count {
                            RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Theme.mint)
                                .shadow(color: Theme.hex(0x7A5000).opacity(0.18), radius: 0, y: 3)
                            Text(String(letters[i]))
                                .font(Theme.font(20, .black)).foregroundStyle(.white)
                        } else if i == 0 && !solvedToday {
                            RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Theme.card)
                                .shadow(color: Theme.hex(0x7A5000).opacity(0.18), radius: 0, y: 3)
                            RoundedRectangle(cornerRadius: 2).fill(Theme.coral)
                                .frame(width: 3, height: 20)
                                .opacity(reduceMotion ? 0.75 : (caretOn ? 0.75 : 0.25))
                        } else {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(.white.opacity(0.42))
                                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .strokeBorder(.white, lineWidth: 2.5))
                        }
                    }
                    .frame(width: 44, height: 44)
                }
            }
            .rotationEffect(.degrees(-1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(solvedToday ? "Today's word, solved" : "Play today's word")
    }

    private var eyebrow: some View {
        Text("WORD \(WordleGame.puzzleNumber()) · SIX TRIES")
            .font(Theme.font(10.5, .black))
            .tracking(1.5)
            .foregroundStyle(Self.eyebrowInk)
            .padding(.horizontal, 13).padding(.vertical, 5)
            .background(Capsule().fill(Theme.card))
    }

    // MARK: - Stats

    private var statChips: some View {
        HStack(spacing: 10) {
            statChip(value: "\(state.wordleStreak)", label: "STREAK",
                     plate: Theme.hex(0xFFEEDC)) { FlameGlyph() }
            statChip(value: "\(state.game.wordleSolved)", label: "SOLVED",
                     plate: Theme.hex(0xE4F7EE)) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Theme.hex(0x2A9C72))
            }
            statChip(value: state.game.wordleBest.map(String.init) ?? "—", label: "BEST",
                     plate: Theme.hex(0xFDF3D9)) { TrophyGlyph() }
        }
        .padding(.horizontal, 20)
    }

    private func statChip<G: View>(value: String, label: String, plate: Color,
                                   @ViewBuilder glyph: () -> G) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(plate)
                .frame(width: 26, height: 26)
                .overlay { glyph() }
            Text(value)
                .font(Theme.font(22, .black))
                .tracking(-0.8)
                .foregroundStyle(Theme.hex(0x2E2822))
                .contentTransition(.numericText())
            Text(label)
                .font(Theme.font(9.5, .black))
                .tracking(0.9)
                .foregroundStyle(Self.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11).padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.card)
            .shadow(color: Theme.hex(0x2E2822).opacity(0.10), radius: 7, y: 4))
    }

    // MARK: - CTA

    private var cta: some View {
        Button { playing = true } label: {
            // Ink on coral, not white: white on #FF6F61 measures 2.7:1, ink measures
            // 5.1:1, and the coral itself stays the brand coral.
            HStack(spacing: 9) {
                Text(solvedToday ? "See today's board"
                     : (outOfTries ? "See the answer" : "Play today's word"))
                    .font(Theme.font(16.5, .black))
                    .foregroundStyle(Self.inkOnButter)
                if !solvedToday && !outOfTries {
                    HStack(spacing: 4) {
                        CoinDisc(size: 10)
                        Text("+30").font(Theme.font(12.5, .black)).foregroundStyle(Self.inkOnButter)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.42)))
                }
            }
            .frame(maxWidth: .infinity).frame(height: 58)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.coral))
        }
        .buttonStyle(PushStyle(shadow: Self.coralShadow))
        .padding(.horizontal, 24)
    }

    // MARK: - Rail

    private var railHeader: some View {
        Text("MORE TO PLAY")
            .font(Theme.font(10.5, .black))
            .tracking(1.4)
            .foregroundStyle(Self.inkMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
    }

    private var rail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 11) {
                ForEach(GameCard.catalogue) { card in
                    Button {
                        if card.id == "numberline" { playingNumberLine = true } else { locked = card }
                    } label: { railCard(card) }
                        .buttonStyle(PressStyle(scale: 0.97))
                }
                // The unannounced slot: a dashed outline, not a fill.
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.hex(0xDDD3C4), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    .frame(width: 152, height: 118)
                    .overlay {
                        Text("?")
                            .font(Theme.font(17, .black))
                            .foregroundStyle(Theme.dim)
                            .frame(width: 34, height: 34)
                            .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(Theme.card))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(14)
                    }
            }
            .padding(.horizontal, 24)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }

    private var liveNumberLineLabel: String {
        if state.numberLineClaimedToday {
            return state.game.numberLineBest.map { "Best \($0)% · play again" } ?? "Play again"
        }
        return "Ten quick ones · +25"
    }

    private func railCard(_ card: GameCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Theme.card)
                .frame(width: 34, height: 34)
                .overlay { card.glyph }
            Spacer(minLength: 0)
            Text(card.name)
                .font(Theme.font(17, .black))
                .tracking(-0.3)
                .foregroundStyle(card.ink)
            if let progress = card.progress(coins: state.coins) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(card.ink.opacity(0.22))
                        Capsule().fill(.white).frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 5)
                .padding(.top, 6)
            }
            Text(card.id == "numberline" ? liveNumberLineLabel : card.unlockLabel)
                .font(Theme.font(10.5, .black))
                .foregroundStyle(card.ink)
                .padding(.top, 5)
        }
        .padding(13)
        .frame(width: 152, height: 118, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(card.fill)
                .overlay(alignment: .topTrailing) {
                    Circle().fill(.white.opacity(0.18)).frame(width: 70, height: 70)
                        .offset(x: 16, y: -16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }
}

// MARK: - Catalogue

/// A game that is not live yet. `unlockLabel` says what unlocks it; `progress` is
/// only non-nil when there is a real number behind it.
struct GameCard: Identifiable {
    let id: String
    let name: String
    let fill: Color
    let ink: Color
    let glyphInk: Color
    let unlockLabel: String
    let unlockDetail: String
    var coinThreshold: Int? = nil

    func progress(coins: Int) -> Double? {
        guard let coinThreshold else { return nil }
        return min(1, Double(coins) / Double(coinThreshold))
    }

    @ViewBuilder var glyph: some View {
        switch id {
        case "versus":
            Image(systemName: "person.2.fill")
                .font(.system(size: 15, weight: .bold)).foregroundStyle(glyphInk)
        default:
            Text("7").font(Theme.font(16, .black)).foregroundStyle(glyphInk)
        }
    }

    static let catalogue: [GameCard] = [
        GameCard(id: "versus", name: "Versus",
                 fill: Theme.hex(0x4CA8E8), ink: Theme.hex(0x0B3652), glyphInk: Theme.hex(0x1F79B8),
                 unlockLabel: "Needs a friend",
                 unlockDetail: "Word battles, head to head. It switches on once you and a friend have paired on the Friends tab."),
        GameCard(id: "numberline", name: "Number Line",
                 fill: Theme.hex(0x9B7BEA), ink: Theme.hex(0x2A1A57), glyphInk: Theme.hex(0x6B4FBF),
                 unlockLabel: "Ten quick ones · +25",
                 unlockDetail: "Ten numbers. Put each one where it belongs on the line."),
    ]
}

private struct LockedGameSheet: View {
    let card: GameCard
    let coins: Int

    var body: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(card.fill).frame(width: 52, height: 52)
                .overlay { card.glyph.colorMultiply(.white) }
                .padding(.top, 28)
            Text(card.name).font(Theme.font(24, .black)).foregroundStyle(Theme.ink)
            Text(card.unlockDetail)
                .font(Theme.font(14.5, .bold)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            if let progress = card.progress(coins: coins), let threshold = card.coinThreshold {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.hairline)
                            Capsule().fill(card.fill).frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 8)
                    Text("\(coins) of \(threshold)")
                        .font(Theme.font(12, .heavy)).foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 28).padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.paper)
    }
}

// MARK: - Pieces

/// The CTA's hard offset shadow: 5pt at rest, 2pt and pushed down while pressed.
struct PushStyle: ButtonStyle {
    let shadow: Color
    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed
        return configuration.label
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(shadow).offset(y: down ? 2 : 5))
            .offset(y: down ? 3 : 0)
            .animation(.easeOut(duration: 0.09), value: down)
    }
}

private struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// `kbob`: 3pt up and back over 2.4s.
private struct Bob: ViewModifier {
    let enabled: Bool
    @State private var up = false
    func body(content: Content) -> some View {
        content
            .offset(y: enabled && up ? -3 : 0)
            .onAppear {
                guard enabled else { return }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { up = true }
            }
    }
}

/// `sparkle`: fades in and grows, 2.8s loop.
private struct Sparkle: View {
    enum Kind { case square, dot }
    let shape: Kind
    let color: Color
    let size: CGFloat
    var delay: Double = 0
    @State private var on = false

    var body: some View {
        Group {
            if shape == .square {
                RoundedRectangle(cornerRadius: 3).fill(color).rotationEffect(.degrees(22))
            } else {
                Circle().fill(color)
            }
        }
        .frame(width: size, height: size)
        .opacity(on ? 1 : 0)
        .scaleEffect(on ? 1 : 0.4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(delay)) { on = true }
        }
    }
}

private struct FlameGlyph: View {
    var body: some View {
        ZStack {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.hex(0xFF8A3D))
            Image(systemName: "flame.fill")
                .font(.system(size: 7, weight: .bold)).foregroundStyle(Theme.coin)
                .offset(y: 3)
        }
    }
}

private struct TrophyGlyph: View {
    var body: some View {
        Image(systemName: "trophy.fill")
            .font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.hex(0xF2C230))
    }
}
