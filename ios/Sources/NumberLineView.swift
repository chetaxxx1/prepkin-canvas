import SwiftUI

// MARK: - Model

/// Number Line: ten numbers a day, put each where it belongs on a line.
///
/// Number-line estimation is one of the few maths games with real evidence behind
/// it (Siegler & Booth's work on number sense): placing 37 on 0–100, ¾ on 0–1, or
/// −8 on −20…20 is the mental model everything else in arithmetic sits on. Each
/// prompt is a placement, and about a third of them hide a small sum first so it
/// stays a game rather than a drill.
///
/// The ten are dealt from the day, so friends get the same round. Accuracy is a
/// score to beat; the coins are for finishing, same as everything else.
struct NumberLinePrompt: Identifiable, Equatable {
    let id: Int
    /// What the student reads. "37", "3/4", "48 + 27", "−8".
    let label: String
    /// Where it belongs.
    let answer: Double
    let lo: Double
    let hi: Double
    /// Labelled ticks. Ends are always drawn; these are the ones in between.
    let ticks: [Double]

    var range: Double { hi - lo }

    /// How a position on this line is written. Whole lines get whole numbers,
    /// unit lines get two decimals.
    func format(_ value: Double) -> String {
        if range <= 1.5 { return String(format: "%.2f", value) }
        if range <= 12 { return String(format: "%.1f", value) }
        let rounded = Int(value.rounded())
        return rounded < 0 ? "−\(abs(rounded))" : "\(rounded)"
    }
}

enum NumberLineRound {
    static let count = 10

    /// Dealt from the day so everyone on the same date gets the same ten.
    static func deal(for day: DayKey) -> [NumberLinePrompt] {
        var h: UInt64 = 0xcbf29ce484222325
        for b in day.raw.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        var rng = SplitMix64(seed: h)
        var out: [NumberLinePrompt] = []

        func int(_ r: ClosedRange<Int>) -> Int { Int.random(in: r, using: &rng) }

        // 1–3: whole numbers on 0–100. Warm-up.
        for _ in 0..<3 {
            let n = int(3...97)
            out.append(.init(id: out.count, label: "\(n)", answer: Double(n),
                             lo: 0, hi: 100, ticks: [50]))
        }
        // 4: a fraction on 0–1.
        do {
            let pairs = [(1, 4), (3, 4), (1, 3), (2, 3), (1, 5), (2, 5), (3, 5), (4, 5), (1, 8), (5, 8), (7, 8)]
            let (a, b) = pairs[int(0...(pairs.count - 1))]
            out.append(.init(id: out.count, label: "\(a)/\(b)", answer: Double(a) / Double(b),
                             lo: 0, hi: 1, ticks: [0.5]))
        }
        // 5: a decimal on 0–1.
        do {
            let d = Double(int(5...95)) / 100
            out.append(.init(id: out.count, label: String(format: "%.2f", d), answer: d,
                             lo: 0, hi: 1, ticks: [0.5]))
        }
        // 6: a sum on 0–100.
        do {
            let a = int(11...58), b = int(11...39)
            out.append(.init(id: out.count, label: "\(a) + \(b)", answer: Double(a + b),
                             lo: 0, hi: 100, ticks: [50]))
        }
        // 7: a negative on −20…20.
        do {
            let n = int(-18...(-2))
            out.append(.init(id: out.count, label: "−\(abs(n))", answer: Double(n),
                             lo: -20, hi: 20, ticks: [0]))
        }
        // 8: a percentage of something, on 0–that thing.
        do {
            let whole = [40, 60, 80, 120, 200][int(0...4)]
            let pct = [10, 25, 30, 40, 60, 75][int(0...5)]
            out.append(.init(id: out.count, label: "\(pct)% of \(whole)",
                             answer: Double(whole) * Double(pct) / 100,
                             lo: 0, hi: Double(whole), ticks: [Double(whole) / 2]))
        }
        // 9: a difference on 0–100.
        do {
            let a = int(60...99), b = int(12...45)
            out.append(.init(id: out.count, label: "\(a) − \(b)", answer: Double(a - b),
                             lo: 0, hi: 100, ticks: [50]))
        }
        // 10: a product on 0–1000 — the one you have to think about.
        do {
            let a = int(12...29), b = int(11...34)
            out.append(.init(id: out.count, label: "\(a) × \(b)", answer: Double(a * b),
                             lo: 0, hi: 1000, ticks: [500]))
        }
        return out
    }

    /// 0–100 for one placement. Two percent of the line off is still 90; a fifth of
    /// the line off is nothing. Averaged over the round.
    static func score(guess: Double, prompt: NumberLinePrompt) -> Int {
        let offPct = abs(guess - prompt.answer) / prompt.range * 100
        return max(0, Int((100 - offPct * 5).rounded()))
    }
}

// MARK: - View

/// Same grammar as the Daily Word board — a colour band up top with the round's
/// number and the reward, one big thing to look at, one control, one button —
/// in Number Line's own purple.
struct NumberLineView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var prompts: [NumberLinePrompt] = []
    @State private var index = 0
    /// 0–1 along the line. Starts in the middle: nothing is pre-answered.
    @State private var fraction: Double = 0.5
    @State private var locked = false
    @State private var scores: [Int] = []
    @State private var paid: Int?
    @State private var alreadyClaimed = false

    private static let field = Theme.hex(0x9B7BEA)
    private static let fieldDeep = Theme.hex(0x6B4FBF)
    private static let ink = Theme.hex(0x2A1A57)
    private static let inkOnCoral = Theme.hex(0x3A2A05)

    private var prompt: NumberLinePrompt? { index < prompts.count ? prompts[index] : nil }
    private var finished: Bool { !prompts.isEmpty && index >= prompts.count }
    private var accuracy: Int { scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                progressDots.padding(.top, 14)
                if let prompt {
                    kinLine(prompt).padding(.top, 14)
                    promptCard(prompt).padding(.top, 16)
                    line(prompt).padding(.top, 26)
                    feedback(prompt).padding(.top, 18)
                    Spacer(minLength: 8)
                    button(prompt).padding(.bottom, 30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if finished { endCard.transition(.move(edge: .bottom).combined(with: .opacity)) }
        }
        .background(Theme.paper)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: finished)
        .onAppear {
            guard prompts.isEmpty else { return }
            alreadyClaimed = state.numberLineClaimedToday
            prompts = NumberLineRound.deal(for: state.game.effectiveDay)
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack(alignment: .top) {
            Self.field
            VStack(spacing: 10) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Self.ink)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Theme.card))
                    }
                    .accessibilityLabel("Back to Games")
                    Spacer()
                    Text("ROUND \(WordleGame.puzzleNumber()) · \(min(index + 1, NumberLineRound.count)) OF \(NumberLineRound.count)")
                        .font(Theme.font(10.5, .black))
                        .tracking(1.5)
                        .foregroundStyle(Self.fieldDeep)
                        .padding(.horizontal, 13).padding(.vertical, 6)
                        .background(Capsule().fill(Theme.card))
                    Spacer()
                    HStack(spacing: 5) {
                        CoinDisc(size: 13)
                        Text(alreadyClaimed ? "25" : "+25")
                            .font(Theme.font(13, .black)).foregroundStyle(Self.ink)
                    }
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(Capsule().fill(Theme.card))
                    .opacity(alreadyClaimed ? 0.6 : 1)
                }
                Text("Number Line")
                    .font(Theme.font(28, .black))
                    .tracking(-0.9)
                    .foregroundStyle(Self.ink)
            }
            .padding(.horizontal, 20)
            .padding(.top, 64)
        }
        .frame(height: 168)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30,
                                          style: .continuous))
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<NumberLineRound.count, id: \.self) { i in
                Capsule()
                    .fill(i < scores.count ? dotColor(scores[i]) : (i == index ? Self.field : Theme.hairline))
                    .frame(width: i == index && !finished ? 22 : 10, height: 6)
            }
        }
        .animation(.snappy, value: index)
    }

    private func dotColor(_ score: Int) -> Color {
        score >= 90 ? Theme.mint : (score >= 60 ? Theme.coin : Theme.dim)
    }

    // MARK: Prompt

    private func kinLine(_ prompt: NumberLinePrompt) -> some View {
        HStack(spacing: 9) {
            SproutFace(speciesID: state.activeChibiID, size: 34,
                       plate: Theme.species(state.activeChibiID).opacity(0.35))
            Text(kinCopy(prompt))
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

    private func kinCopy(_ prompt: NumberLinePrompt) -> String {
        if locked, let last = scores.last {
            if last >= 95 { return "Spot on." }
            if last >= 80 { return "Close. I'd take that." }
            return "Off a bit. The mint dot is where it lives."
        }
        switch index {
        case 0: return "Drag the dot. Halfway is \(prompt.format((prompt.lo + prompt.hi) / 2))."
        case 3: return "A fraction now. Think of it as a slice."
        case 5: return "Work it out first, then place it."
        case 6: return "Left of zero this time."
        case 9: return "Last one. Roughly is fine."
        default: return "Where does it go?"
        }
    }

    private func promptCard(_ prompt: NumberLinePrompt) -> some View {
        VStack(spacing: 6) {
            Text("WHERE IS")
                .font(Theme.font(10.5, .black))
                .tracking(1.5)
                .foregroundStyle(Theme.muted)
            Text(prompt.label)
                .font(Theme.font(44, .black))
                .tracking(-1.2)
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.card)
            .shadow(color: Theme.hex(0x2E2822).opacity(0.06), radius: 8, y: 3))
        .padding(.horizontal, 24)
    }

    // MARK: Line

    private func line(_ prompt: NumberLinePrompt) -> some View {
        GeometryReader { geo in
            let inset: CGFloat = 26
            let width = geo.size.width - inset * 2
            let x = inset + width * fraction
            let truth = inset + width * ((prompt.answer - prompt.lo) / prompt.range)
            let guessValue = prompt.lo + prompt.range * fraction

            ZStack(alignment: .topLeading) {
                // Track and ticks.
                Capsule().fill(Theme.hex(0xE6DFD7)).frame(width: width, height: 6)
                    .offset(x: inset, y: 48)
                ForEach([prompt.lo] + prompt.ticks + [prompt.hi], id: \.self) { t in
                    let tx = inset + width * ((t - prompt.lo) / prompt.range)
                    Rectangle().fill(Theme.dim).frame(width: 2, height: 14)
                        .offset(x: tx - 1, y: 44)
                    Text(prompt.format(t))
                        .font(Theme.font(12, .heavy))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 60)
                        .offset(x: tx - 30, y: 64)
                }

                // The truth, once locked: a mint dot and a short bracket to the guess.
                if locked {
                    Capsule().fill(Theme.mint.opacity(0.35))
                        .frame(width: max(4, abs(truth - x)), height: 6)
                        .offset(x: min(truth, x), y: 48)
                    Circle().fill(Theme.mint)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                        .frame(width: 22, height: 22)
                        .offset(x: truth - 11, y: 40)
                    Text(prompt.format(prompt.answer))
                        .font(Theme.font(12, .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Theme.mint))
                        .frame(width: 80)
                        .offset(x: truth - 40, y: 88)
                }

                // The marker and its value bubble.
                Text(prompt.format(guessValue))
                    .font(Theme.font(14, .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Self.fieldDeep))
                    .frame(width: 90)
                    .offset(x: x - 45, y: 0)
                Circle().fill(Self.field)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    .shadow(color: Self.fieldDeep.opacity(0.35), radius: 6, y: 3)
                    .frame(width: 30, height: 30)
                    // Scale before offset: after it, the scale is about the
                    // un-offset centre and drags the marker sideways.
                    .scaleEffect(locked ? 0.85 : 1)
                    .offset(x: x - 15, y: 36)
            }
            // Offsets do not grow the stack, so without this the hit area is a
            // 30pt strip at the top and the track itself cannot be touched.
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        guard !locked else { return }
                        fraction = min(1, max(0, (g.location.x - inset) / width))
                    }
            )
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8), value: locked)
        }
        .frame(height: 112)
        .padding(.horizontal, 24)
        .accessibilityElement()
        .accessibilityLabel("Number line from \(prompt.format(prompt.lo)) to \(prompt.format(prompt.hi))")
        .accessibilityValue(prompt.format(prompt.lo + prompt.range * fraction))
        .accessibilityAdjustableAction { direction in
            guard !locked else { return }
            fraction = min(1, max(0, fraction + (direction == .increment ? 0.02 : -0.02)))
        }
    }

    // MARK: Feedback and buttons

    @ViewBuilder private func feedback(_ prompt: NumberLinePrompt) -> some View {
        if locked, let last = scores.last {
            let off = abs(prompt.lo + prompt.range * fraction - prompt.answer)
            HStack(spacing: 8) {
                Text(last >= 95 ? "Spot on" : (last >= 80 ? "Close" : "Off by \(prompt.format(off))"))
                    .font(Theme.font(15, .black))
                    .foregroundStyle(last >= 80 ? Theme.mintDark : Theme.ink)
                Text("· \(last)")
                    .font(Theme.font(15, .heavy))
                    .foregroundStyle(Theme.muted)
            }
            .transition(.opacity)
        } else {
            Text(" ").font(Theme.font(15, .black))
        }
    }

    private func button(_ prompt: NumberLinePrompt) -> some View {
        Button {
            if locked { next() } else { lock(prompt) }
        } label: {
            Text(locked ? (index == prompts.count - 1 ? "Finish" : "Next") : "Lock it in")
                .font(Theme.font(16.5, .black))
                .foregroundStyle(Self.inkOnCoral)
                .frame(maxWidth: .infinity).frame(height: 58)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.coral))
        }
        .buttonStyle(PushStyle(shadow: Theme.hex(0xE15546)))
        .padding(.horizontal, 24)
    }

    private func lock(_ prompt: NumberLinePrompt) {
        let guess = prompt.lo + prompt.range * fraction
        let s = NumberLineRound.score(guess: guess, prompt: prompt)
        scores.append(s)
        withAnimation { locked = true }
        UIImpactFeedbackGenerator(style: s >= 90 ? .medium : .light).impactOccurred()
    }

    private func next() {
        if index == prompts.count - 1 {
            paid = state.finishNumberLineRound(accuracy: accuracy)
        }
        withAnimation(.easeOut(duration: 0.2)) {
            index += 1
            locked = false
            fraction = 0.5
        }
    }

    // MARK: End

    private var endCard: some View {
        VStack(spacing: 10) {
            SproutImage(speciesID: state.activeChibiID,
                        level: state.activeChibi.level,
                        animation: accuracy >= 60 ? .celebrate : .bounce,
                        size: 120)
            Text("\(accuracy)% on the line.")
                .font(Theme.font(24, .black))
                .foregroundStyle(Theme.ink)
            Text(endLine)
                .font(Theme.font(13.5, .bold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                CoinDisc(size: 15)
                Text((paid ?? 0) > 0 ? "+25 coins banked" : "Today's 25 already banked")
                    .font(Theme.font(13.5, .heavy)).foregroundStyle(Theme.coinDark)
            }
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(Capsule().fill(Theme.coinSoft))
            Button { dismiss() } label: {
                Text("Back to Games")
                    .font(Theme.font(16.5, .black)).foregroundStyle(Self.inkOnCoral)
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
        let best = state.game.numberLineBest ?? 0
        if accuracy >= best && accuracy > 0 { return "Your best round. New ten tomorrow." }
        return "Best is \(best)%. New ten tomorrow."
    }
}
