import SwiftUI

/// What is left of the Games tab. The tab itself went on 2026-09-06: Daily Word
/// and Number Line are the Play section on Learn (design/hicks-law-plan.md), which
/// took the tab bar from six to five. The catalogue, the locked-game sheet (kept
/// for Versus, per the 2026-09-05 decision) and the push button style stay here.

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

    /// True when the only thing between the student and this game is another
    /// person. There is no number to fill a bar with, so the sheet offers the one
    /// real step instead of inventing one.
    var needsFriend: Bool = false

    /// The sheet is as tall as what it draws, counted at the medium text size. Since
    /// `Theme.font` began following the system size (capped at 1.3×) the copy can run
    /// a line longer, so the count carries a line of slack. No card uses this sheet
    /// today (Versus is off the rail); measure the content before one does.
    var sheetHeight: CGFloat {
        var h: CGFloat = 250            // top pad, glyph, name, three lines, bottom pad, home indicator
        if coinThreshold != nil { h += 46 }
        if needsFriend { h += 68 }
        return h + (Theme.readingScale - 1) * 60
    }

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

    /// Versus is not on the rail until friends work. Its card promised "it switches
    /// on once you and a friend have added each other's codes" while the Friends
    /// tab says friends are not switched on, and a card that only opens a dead-end
    /// sheet is the padlock PRODUCT.md bans. The card, `needsFriend` and the sheet
    /// stay in the code; put `versus` back here when Friends goes live.
    static let versus = GameCard(
        id: "versus", name: "Versus",
        fill: Theme.hex(0x4CA8E8), ink: Theme.hex(0x0B3652), glyphInk: Theme.hex(0x1F79B8),
        unlockLabel: "Needs a friend",
        unlockDetail: "Word battles, head to head. It switches on once you and a friend have added each other's codes.",
        needsFriend: true)

    static let catalogue: [GameCard] = [
        GameCard(id: "numberline", name: "Number Line",
                 fill: Theme.hex(0x9B7BEA), ink: Theme.hex(0x2A1A57), glyphInk: Theme.hex(0x6B4FBF),
                 unlockLabel: "Ten quick ones · +25",
                 unlockDetail: "Ten numbers. Put each one where it belongs on the line."),
    ]
}

private struct LockedGameSheet: View {
    let card: GameCard
    let coins: Int
    let onAddFriend: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(card.fill).frame(width: 52, height: 52)
                .overlay { card.glyph.colorMultiply(.white) }
                .padding(.top, 26)
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
            // Versus is gated on a person, not a coin count, so there is no bar to
            // draw. The sheet ends on the step that is actually true instead.
            if card.needsFriend {
                Button(action: onAddFriend) {
                    Text("Add a friend")
                        .font(Theme.font(17, .heavy))
                        // Ink on coral, for the reason the Play button gives above:
                        // white on #FF6F61 measures 2.7:1.
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Theme.coral))
                }
                .buttonStyle(PressStyle())
                .padding(.horizontal, 22)
            }
        }
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
