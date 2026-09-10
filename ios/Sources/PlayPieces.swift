import SwiftUI

/// Pieces the Play games added on 2026-09-08 share (design/GAMES-PLAN.md): the
/// day's deal, the stopwatch, the coloured header, the kin line and the end card.
/// Daily Word and Number Line came first and draw their own; nothing here touches
/// them.

// MARK: - The deal

enum PlayDeal {
    /// Counts up one a day from the first puzzle, the same clock Daily Word uses,
    /// so "Pearls 251" and "Word 251" are the same day.
    static func number(for date: Date = Date(), calendar: Calendar = .current) -> Int {
        // Same sum as WordleGame.puzzleNumber, repeated here because that one is
        // main-actor bound and the deal has to be readable from a test or a task.
        let first = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? date
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: first),
                                           to: calendar.startOfDay(for: date)).day ?? 0
        return max(1, days + 1)
    }

    /// Sunday is the big board.
    static func isSunday(_ date: Date = Date(), calendar: Calendar = .current) -> Bool {
        calendar.component(.weekday, from: date) == 1
    }

    /// Today's entry from a content list. Every phone gets the same one without a
    /// server; the list wraps when the year runs out.
    static func pick<T>(_ list: [T], number: Int) -> T? {
        list.isEmpty ? nil : list[(max(1, number) - 1) % list.count]
    }
}

extension CoinReason {
    /// How a Play game names itself on the rail and the end card.
    var playName: String? {
        switch self {
        case .wordle: return "Daily Word"
        case .numberLine: return "Number Line"
        case .balance: return "Balance"
        case .pearls: return "Pearls"
        case .trace: return "Trace"
        case .sort: return "Sort"
        case .weave: return "Weave"
        default: return nil
        }
    }
}

// MARK: - Time

enum PlayClock {
    /// "1:42". Whole seconds; nobody compares tenths.
    static func label(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded()))
        return "\(s / 60):" + String(format: "%02d", s % 60)
    }
}

/// Counts up from the first tap. A stopwatch, never a countdown — the time is the
/// number friends compare, not a limit.
struct PlayStopwatch: View {
    let since: Date?
    /// Set once the board is solved; the display stops there.
    let frozen: TimeInterval?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(label(at: context.date))
                .font(Theme.font(12.5, .black))
                .monospacedDigit()
                .foregroundStyle(Theme.muted)
        }
        .accessibilityLabel("Time \(label(at: Date()))")
    }

    private func label(at now: Date) -> String {
        if let frozen { return PlayClock.label(frozen) }
        guard let since else { return "0:00" }
        return PlayClock.label(now.timeIntervalSince(since))
    }
}

// MARK: - Header

/// The coloured band at the top of a game, same bones as Daily Word's: back
/// button, an eyebrow capsule, the coin chip, the title.
struct PlayHeader: View {
    let fill: Color
    let ink: Color
    let eyebrowInk: Color
    let eyebrow: String
    let title: String
    let line: String
    /// True once the pool is spent, so the chip reads "30" instead of "+30".
    let banked: Bool
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            fill
            VStack(spacing: 10) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(ink)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Theme.card))
                    }
                    .accessibilityLabel("Back to Learn")
                    Spacer()
                    Text(eyebrow)
                        .font(Theme.font(10.5, .black))
                        .tracking(1.5)
                        .foregroundStyle(eyebrowInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 13).padding(.vertical, 6)
                        .background(Capsule().fill(Theme.card))
                    Spacer()
                    HStack(spacing: 5) {
                        CoinDisc(size: 13)
                        Text(banked ? "30" : "+30")
                            .font(Theme.font(13, .black))
                            .foregroundStyle(ink)
                    }
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(Capsule().fill(Theme.card))
                    .opacity(banked ? 0.6 : 1)
                    .accessibilityLabel(banked ? "Today's 30 coins already banked" : "30 coins for the first finish today")
                }
                Text(title)
                    .font(Theme.font(28, .black))
                    .tracking(-0.9)
                    .foregroundStyle(ink)
                Text(line)
                    .font(Theme.font(13, .heavy))
                    .foregroundStyle(ink.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 20)
            .padding(.top, 64)
        }
        .frame(height: 188)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30,
                                          style: .continuous))
    }
}

// MARK: - Kin line

/// Sprout's one line about the board, same as Daily Word's.
struct PlayKinLine: View {
    @EnvironmentObject var state: AppState
    let copy: String

    var body: some View {
        HStack(spacing: 9) {
            SproutFace(speciesID: state.activeChibiID, size: 34, plate: Theme.plate(for: state.activeChibiID))
            Text(copy)
                .font(Theme.font(13.5, .heavy))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card))
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - End card

/// Slides up over the board when it is done. The result line is the share hook:
/// plain text, no emoji, one line a friend can read in a group chat.
struct PlayEndCard: View {
    @EnvironmentObject var state: AppState
    let title: String
    let line: String
    /// What this finish paid. Nil for a miss, which shows no coin chip at all.
    let paid: Int?
    let share: String
    let ink: Color
    let onDone: () -> Void

    @State private var copied = false

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(Theme.font(24, .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(line)
                .font(Theme.font(13.5, .bold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            if let paid {
                HStack(spacing: 6) {
                    CoinDisc(size: 15)
                    Text(coinLine(paid))
                        .font(Theme.font(13.5, .heavy)).foregroundStyle(Theme.coinDark)
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(Capsule().fill(Theme.coinSoft))
            }
            // The rating, the way a chess site shows it: the number, then what this
            // board did to it. Only the five rated games use this card, so there is
            // nothing to switch on. A rating that did not move shows no delta rather
            // than a "+0", and a drop is never shown anywhere but here.
            if state.rating.settled > 0 {
                HStack(spacing: 6) {
                    Text("Rating")
                        .font(Theme.font(11.5, .black)).tracking(0.6)
                        .foregroundStyle(Theme.muted)
                    Text(state.rating.display)
                        .font(Theme.font(13.5, .heavy)).foregroundStyle(Theme.ink)
                    if state.rating.lastDelta != 0 {
                        Text(state.rating.lastDelta > 0 ? "+\(state.rating.lastDelta)"
                                                        : "\(state.rating.lastDelta)")
                            .font(Theme.font(13.5, .heavy))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(Capsule().fill(Theme.checkFill))
            }
            Button {
                UIPasteboard.general.string = share
                copied = true
            } label: {
                // Side by side, not overlaid: a long share line wraps to two rows
                // and must never run under the Copy label.
                HStack(alignment: .center, spacing: 10) {
                    Text(share)
                        .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(copied ? "Copied" : "Copy")
                        .font(Theme.font(11, .black))
                        .foregroundStyle(copied ? Theme.mintDark : Theme.muted)
                        .fixedSize()
                }
                .padding(.horizontal, 12).padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.tile))
            }
            .buttonStyle(PressStyle(scale: 0.98))
            .accessibilityLabel(copied ? "Result copied" : "Copy result: \(share)")
            Button(action: onDone) {
                Text("Done")
                    .font(Theme.font(16.5, .black)).foregroundStyle(ink)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
            .padding(.top, 2)
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

    private func coinLine(_ paid: Int) -> String {
        if paid > 0 { return "+\(paid) coins banked" }
        if let by = state.playBankedBy?.playName { return "Today's 30 banked by \(by)" }
        return "Today's 30 already banked"
    }
}

// MARK: - Rail glyphs

/// The small drawn mark on each Play tile. Vector, never emoji.
enum PlayGlyph {
    case letter(String, Color)
    case pearl
    case dots
    case trace
    case sort
    case weave
}

struct PlayGlyphView: View {
    let glyph: PlayGlyph

    var body: some View {
        switch glyph {
        case .letter(let s, let ink):
            Text(s).font(Theme.font(16, .black)).foregroundStyle(ink)
        case .pearl:
            Circle().fill(.white)
                .overlay(Circle().strokeBorder(Theme.hex(0x0B3652), lineWidth: 2.5))
                .overlay(alignment: .topLeading) {
                    Circle().fill(Theme.hex(0x0B3652).opacity(0.18)).frame(width: 4, height: 4).offset(x: 4, y: 4)
                }
                .frame(width: 18, height: 18)
        case .dots:
            HStack(spacing: 3) {
                Circle().fill(Theme.hex(0x2F4712)).frame(width: 9, height: 9)
                Circle().strokeBorder(Theme.hex(0x2F4712), lineWidth: 2.5).frame(width: 9, height: 9)
            }
        case .trace:
            // A line snaking through a small grid, a dot on the start.
            Path { p in
                p.move(to: CGPoint(x: 3, y: 3))
                p.addLine(to: CGPoint(x: 15, y: 3))
                p.addLine(to: CGPoint(x: 15, y: 9))
                p.addLine(to: CGPoint(x: 3, y: 9))
                p.addLine(to: CGPoint(x: 3, y: 15))
                p.addLine(to: CGPoint(x: 15, y: 15))
            }
            .stroke(Theme.hex(0x2A1A57), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .frame(width: 18, height: 18)
            .overlay(alignment: .topLeading) {
                Circle().fill(Theme.hex(0x2A1A57)).frame(width: 6, height: 6)
            }
        case .sort:
            // Four tiles, one row filled in: a group found.
            VStack(spacing: 2.5) {
                HStack(spacing: 2.5) {
                    RoundedRectangle(cornerRadius: 2).fill(Theme.hex(0x5A2A0E)).frame(width: 8, height: 8)
                    RoundedRectangle(cornerRadius: 2).fill(Theme.hex(0x5A2A0E)).frame(width: 8, height: 8)
                }
                HStack(spacing: 2.5) {
                    RoundedRectangle(cornerRadius: 2).strokeBorder(Theme.hex(0x5A2A0E), lineWidth: 2).frame(width: 8, height: 8)
                    RoundedRectangle(cornerRadius: 2).strokeBorder(Theme.hex(0x5A2A0E), lineWidth: 2).frame(width: 8, height: 8)
                }
            }
        case .weave:
            // A line threading three letters, corner to corner.
            Path { p in
                p.move(to: CGPoint(x: 3, y: 15))
                p.addLine(to: CGPoint(x: 9, y: 9))
                p.addLine(to: CGPoint(x: 15, y: 3))
            }
            .stroke(Theme.hex(0x0E4744), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .frame(width: 18, height: 18)
            .overlay {
                ForEach([CGPoint(x: 3, y: 15), CGPoint(x: 9, y: 9), CGPoint(x: 15, y: 3)], id: \.x) { c in
                    Circle().fill(Theme.hex(0x0E4744)).frame(width: 6, height: 6).position(c)
                }
            }
        }
    }
}

// MARK: - Mini boards

/// A puzzle's tile art: a small board that shows the mechanic, not a mark that
/// stands for it. NYT's and Apple News's game icons are all tiny boards — Wordle a
/// block of tiles, Connections four coloured rows, a Strands grid with a word lit —
/// and at a glance that is what says "you know this one" to someone who plays them.
/// The 18pt glyphs in a white box this replaces (2026-09-10) said "an icon".
///
/// Everything is drawn in the tile's own ink at three strengths, so six boards on six
/// colours still read as one family: solid for what's found, a mid wash for what's
/// there, faint for the empty grid.
struct MiniBoard: View {
    let glyph: PlayGlyph
    let ink: Color
    var size: CGFloat = 58

    private var faint: Color { ink.opacity(0.22) }
    private var mid: Color { ink.opacity(0.42) }

    var body: some View {
        Group {
            switch glyph {
            case .letter: wordBoard
            case .trace: traceBoard
            case .pearl: pearlBoard
            case .dots: balanceBoard
            case .sort: sortBoard
            case .weave: weaveBoard
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    // Shared grid maths: three cells across, a two-point gap.
    private var gap: CGFloat { size * 0.06 }
    private var cell: CGFloat { (size - gap * 2) / 3 }
    private func at(_ col: Int, _ row: Int) -> CGPoint {
        CGPoint(x: cell / 2 + CGFloat(col) * (cell + gap), y: cell / 2 + CGFloat(row) * (cell + gap))
    }
    private func square(_ fill: Color, ring: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: cell * 0.22, style: .continuous)
            .fill(ring ? .clear : fill)
            .overlay(RoundedRectangle(cornerRadius: cell * 0.22, style: .continuous)
                .strokeBorder(ring ? fill : .clear, lineWidth: max(1.5, size * 0.035)))
            .frame(width: cell, height: cell)
    }

    /// Daily Word: a solved row on top, the next row half in, the last still empty.
    private var wordBoard: some View {
        VStack(spacing: gap) {
            HStack(spacing: gap) {
                square(ink).overlay(Text("A").font(Theme.font(cell * 0.62, .black)).foregroundStyle(.white))
                square(ink); square(ink)
            }
            HStack(spacing: gap) { square(ink); square(mid, ring: true); square(mid, ring: true) }
            HStack(spacing: gap) { square(faint, ring: true); square(faint, ring: true); square(faint, ring: true) }
        }
    }

    /// Trace: one line through every cell, numbered where it starts.
    private var traceBoard: some View {
        ZStack {
            VStack(spacing: gap) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: gap) { ForEach(0..<3, id: \.self) { _ in square(faint, ring: true) } }
                }
            }
            Path { p in
                p.move(to: at(0, 0)); p.addLine(to: at(2, 0)); p.addLine(to: at(2, 1))
                p.addLine(to: at(0, 1)); p.addLine(to: at(0, 2)); p.addLine(to: at(2, 2))
            }
            .stroke(ink, style: StrokeStyle(lineWidth: max(2.5, size * 0.07), lineCap: .round, lineJoin: .round))
            Circle().fill(ink).frame(width: cell * 0.72, height: cell * 0.72)
                .overlay(Text("1").font(Theme.font(cell * 0.46, .black)).foregroundStyle(.white))
                .position(at(0, 0))
            Circle().fill(ink).frame(width: cell * 0.5, height: cell * 0.5).position(at(2, 2))
        }
    }

    /// Pearls: two reefs, one pearl, the crosses it rules out.
    private var pearlBoard: some View {
        ZStack {
            VStack(spacing: gap) {
                HStack(spacing: gap) { square(mid); square(mid); square(faint) }
                HStack(spacing: gap) { square(faint); square(mid); square(faint) }
                HStack(spacing: gap) { square(faint); square(faint); square(faint) }
            }
            Circle().fill(.white)
                .overlay(Circle().strokeBorder(ink, lineWidth: max(2, size * 0.05)))
                .frame(width: cell * 0.7, height: cell * 0.7)
                .position(at(1, 1))
            // Indexed, not keyed on the column: (1, 0) and (1, 2) share a column,
            // and SwiftUI quietly drew one cross for the two of them.
            ForEach(Array([(0, 1), (2, 1), (1, 0), (1, 2)].enumerated()), id: \.offset) { c in
                cross.position(at(c.element.0, c.element.1))
            }
        }
    }
    private var cross: some View {
        Path { p in
            let r = cell * 0.16
            p.move(to: CGPoint(x: -r, y: -r)); p.addLine(to: CGPoint(x: r, y: r))
            p.move(to: CGPoint(x: r, y: -r)); p.addLine(to: CGPoint(x: -r, y: r))
        }
        .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.04), lineCap: .round))
        .frame(width: 1, height: 1)
    }

    /// Balance: suns and moons, an = between a pair that match.
    private var balanceBoard: some View {
        ZStack {
            VStack(spacing: gap) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: gap) { ForEach(0..<3, id: \.self) { _ in square(faint, ring: true) } }
                }
            }
            sun.position(at(0, 0)); moon.position(at(1, 0)); moon.position(at(2, 0))
            moon.position(at(0, 1)); sun.position(at(1, 1))
            sun.position(at(2, 2))
            Text("=").font(Theme.font(cell * 0.6, .black)).foregroundStyle(ink)
                .position(x: (at(1, 0).x + at(2, 0).x) / 2, y: at(1, 0).y)
        }
    }
    private var sun: some View { Circle().fill(ink).frame(width: cell * 0.5, height: cell * 0.5) }
    private var moon: some View {
        Circle().strokeBorder(ink, lineWidth: max(2, size * 0.05)).frame(width: cell * 0.5, height: cell * 0.5)
    }

    /// Sort: four groups of four, the first one found.
    private var sortBoard: some View {
        let g = gap * 0.8
        let w = (size - g * 3) / 4
        let h = (size - g * 3) / 4
        return VStack(spacing: g) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: g) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: w * 0.22, style: .continuous)
                            .fill(row == 0 ? ink : .clear)
                            .overlay(RoundedRectangle(cornerRadius: w * 0.22, style: .continuous)
                                .strokeBorder(row == 0 ? .clear : (row == 1 ? mid : faint),
                                              lineWidth: max(1.5, size * 0.035)))
                            .frame(width: w, height: h)
                    }
                }
            }
        }
    }

    /// Weave: letters in a grid, one word threaded through.
    private var weaveBoard: some View {
        let lit: [(Int, Int)] = [(0, 2), (1, 1), (2, 0)]
        return ZStack {
            ForEach(0..<9, id: \.self) { i in
                let c = i % 3, r = i / 3
                let on = lit.contains { $0 == (c, r) }
                Circle().fill(on ? ink : faint)
                    .frame(width: cell * (on ? 0.5 : 0.34), height: cell * (on ? 0.5 : 0.34))
                    .position(at(c, r))
            }
            Path { p in p.move(to: at(0, 2)); p.addLine(to: at(1, 1)); p.addLine(to: at(2, 0)) }
                .stroke(ink, style: StrokeStyle(lineWidth: max(2.5, size * 0.07), lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Hint and controls

/// The hint pill every Play game shows: free, counted, the count on the pill.
struct PlayHintButton: View {
    let count: Int
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill").font(.system(size: 10.5, weight: .black))
                Text(count == 0 ? "Hint" : "Hint · \(count)").font(Theme.font(12, .black))
            }
            .foregroundStyle(Theme.coinDark)
            .padding(.horizontal, 11).frame(height: 30)
            .background(Capsule().fill(Theme.coinSoft))
        }
        .buttonStyle(PressStyle(scale: 0.95))
        .accessibilityLabel(label)
    }
}

/// Undo / Clear: a quiet outlined pill in the foot row.
struct PlayControlButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10.5, weight: .black))
                Text(label).font(Theme.font(12, .black))
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 11).frame(height: 30)
            .background(Capsule().fill(Theme.card))
            .overlay(Capsule().strokeBorder(Theme.tileRing, lineWidth: 1.5))
        }
        .buttonStyle(PressStyle(scale: 0.95))
        .accessibilityLabel(label)
    }
}

/// "hints" wording for end cards and share lines.
enum PlayHints {
    static func line(_ n: Int) -> String { n == 0 ? "no hints" : "\(n) hint\(n == 1 ? "" : "s")" }
}

// MARK: - Keyboard

/// Daily Word's keyboard without the letter colours, for games that type words
/// but don't score letters. Same key size and spacing so the two feel alike.
struct PlayKeyboard: View {
    let onKey: (String) -> Void
    let onEnter: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 7) {
            row("QWERTYUIOP")
            row("ASDFGHJKL").padding(.horizontal, 18)
            HStack(spacing: 5) {
                wide(label: "Enter", icon: nil, action: onEnter)
                row("ZXCVBNM")
                wide(label: nil, icon: "delete.left.fill", action: onDelete)
            }
        }
        .padding(.horizontal, 6)
    }

    private func row(_ letters: String) -> some View {
        HStack(spacing: 5) {
            ForEach(letters.map(String.init), id: \.self) { letter in
                Button { onKey(letter) } label: {
                    Text(letter)
                        .font(Theme.font(16, .heavy))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.card)
                            .shadow(color: Theme.hex(0x2E2822).opacity(0.06), radius: 2, y: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func wide(label: String?, icon: String?, action: @escaping () -> Void) -> some View {
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
}
