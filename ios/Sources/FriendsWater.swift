import SwiftUI

/// The Friends tab's hero: this week's board, in your league's water.
///
/// The top three stand on sand mounds — Transit's "Top contributors" podium, the
/// winner in the middle and tallest — and everybody else is a row underneath. An
/// empty mound is a dashed ring where a friend's kin would stand, which does the
/// job three paragraphs used to do: there is room here. Nothing on this card is
/// invented. An empty mound is empty because nobody is on it, and when a friend
/// shares their week their kin lands on it and nothing else changes.
///
/// The water is the tier's own colour, so climbing the ladder is visible on the tab
/// that shows it rather than only inside the ladder screen.
struct FriendsWater: View {
    let tier: LeagueTier
    /// The board, best first. Never empty: you are always on your own board.
    let rows: [BoardRow]
    /// Tapping an empty mound is the same as tapping Add a friend.
    var onEmptyTap: () -> Void = {}
    /// Tapping a kin opens that person.
    var onTap: (BoardRow) -> Void = { _ in }

    private static let ringSize: CGFloat = 64

    /// Where every mound's foot lands: far enough into the sand to stand on it
    /// rather than hover over it.
    private static let floor: CGFloat = 24
    private static let height: CGFloat = 318
    /// How much sand shows. The ellipse is far wider than the card so its crown reads
    /// as a gentle rise rather than a dome.
    private static let sandShown: CGFloat = 56

    var body: some View {
        ZStack(alignment: .bottom) {
            water
            sand
            weeds
            podium
            chips
        }
        .frame(height: Self.height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sheet, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    // MARK: - The water

    private var water: some View {
        ZStack {
            LinearGradient(colors: [tier.color.opacity(0.52),
                                    tier.color.opacity(0.80),
                                    tier.color,
                                    tier.color],
                           startPoint: .top, endPoint: .bottom)
            // The light coming in, always from the same corner as every other
            // highlight in the app.
            RadialGradient(colors: [.white.opacity(0.62), .white.opacity(0)],
                           center: UnitPoint(x: 0.22, y: -0.1),
                           startRadius: 0, endRadius: 250)
            bubbles
        }
        .background(Theme.card)
    }

    private var bubbles: some View {
        // Fixed positions rather than random: a card that redraws must not shuffle
        // its own background while somebody is reading it.
        ZStack {
            bubble(10, x: 0.27, y: 0.30)
            bubble(6, x: 0.33, y: 0.19)
            bubble(13, x: 0.76, y: 0.38)
            bubble(7, x: 0.83, y: 0.26)
            bubble(8, x: 0.50, y: 0.14)
        }
    }

    private func bubble(_ d: CGFloat, x: Double, y: Double) -> some View {
        GeometryReader { geo in
            Circle()
                .fill(.white.opacity(0.30))
                .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1.4))
                .frame(width: d, height: d)
                .position(x: geo.size.width * x, y: geo.size.height * y)
        }
    }

    /// The sea floor. A wide, shallow ellipse mostly below the card, so only its
    /// gentle crown shows and the slots have a line to stand on.
    private var sand: some View {
        GeometryReader { geo in
            let w = geo.size.width * 2.2
            let h: CGFloat = 150
            Ellipse()
                .fill(Theme.hex(0xF3E4C9))
                .overlay(
                    Ellipse().strokeBorder(Theme.hex(0xE3CBA2), lineWidth: 3.5)
                )
                .frame(width: w, height: h)
                // Only `sandShown` of the ellipse clears the card's bottom edge.
                .position(x: geo.size.width / 2,
                          y: geo.size.height - Self.sandShown + h / 2)
        }
        .allowsHitTesting(false)
    }

    /// Weed rooted in the sand. Three clumps, always in the same places, drawn behind
    /// whoever is standing there — a card with nothing but water and a beige strip
    /// reads as a placeholder rather than a place.
    private var weeds: some View {
        HStack(alignment: .bottom, spacing: 0) {
            clump([26, 42, 18])
            Spacer(minLength: 0)
            clump([18, 32, 24])
        }
        .padding(.horizontal, 8)
        .padding(.bottom, Self.sandShown - 8)
        .allowsHitTesting(false)
    }

    private func clump(_ heights: [CGFloat]) -> some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(heights.enumerated()), id: \.offset) { _, h in
                Capsule()
                    .fill(tier.edge.opacity(0.34))
                    .frame(width: 7, height: h)
            }
        }
    }

    // MARK: - The podium

    /// Three mounds: second on the left, first in the middle and tallest, third on
    /// the right. A place with nobody on it is a dashed ring, drawn the way an
    /// unowned kin is drawn everywhere else — full-strength colour, hollow.
    private var podium: some View {
        HStack(alignment: .bottom, spacing: 10) {
            mound(place: 2, row: row(at: 1), kin: 92, hill: 26)
            mound(place: 1, row: row(at: 0), kin: 116, hill: 40)
            mound(place: 3, row: row(at: 2), kin: 84, hill: 16)
        }
        .padding(.bottom, Self.floor)
    }

    private func row(at i: Int) -> BoardRow? { i < rows.count ? rows[i] : nil }

    /// The crown only when there is somebody to have beaten. A board of one has a
    /// fish in the middle and no crown over it, which is the truth.
    private var crowned: Bool { rows.count >= 2 }

    @ViewBuilder private func mound(place: Int, row: BoardRow?, kin: CGFloat, hill: CGFloat) -> some View {
        VStack(spacing: 0) {
            if let row {
                Button { onTap(row) } label: {
                    ZStack(alignment: .top) {
                        SproutImage(speciesID: row.member.speciesID, level: row.member.level,
                                    skin: row.member.lookID, size: kin)
                            .padding(.top, 14)
                        if place == 1, crowned { CrownGlyph(size: 26) }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label(row))
                .offset(y: 12)
                .zIndex(2)
            } else {
                Button(action: onEmptyTap) {
                    ZStack {
                        Circle().fill(.white.opacity(0.30))
                        Circle().strokeBorder(tier.edge.opacity(0.34),
                                              style: StrokeStyle(lineWidth: 2, dash: [12, 9]))
                        Image(systemName: "plus")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(tier.edge.opacity(0.55))
                    }
                    .frame(width: Self.ringSize, height: Self.ringSize)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Room for a friend. Add one.")
                .offset(y: 6)
                .zIndex(2)
            }
            // A low dome, wider than tall, so it reads as sand pushed up rather
            // than a plinth. The kin's feet sink a little into it.
            Ellipse()
                .fill(Theme.hex(0xEFD9B6))
                .overlay(Ellipse().strokeBorder(Theme.hex(0xE3CBA2), lineWidth: 3))
                .frame(width: 104, height: (hill + 10) * 2)
                .frame(height: hill + 10, alignment: .top)
                .clipped()
                .zIndex(1)
            VStack(spacing: 0) {
                Text(row?.member.name ?? " ")
                    .font(Theme.font(12, .heavy))
                    .lineLimit(1)
                Text(row.map { "\($0.member.points)" } ?? " ")
                    .font(Theme.font(11.5, .bold))
                    .opacity(0.85)
            }
            .foregroundStyle(Theme.ink)
            .padding(.top, 2)
            .frame(width: 108)
            .zIndex(3)
        }
        .accessibilityElement(children: .contain)
    }

    private func label(_ r: BoardRow) -> String {
        let who = r.member.isYou ? "You" : r.member.name
        return "\(who), \(Self.ordinal(r.place)), \(r.member.points) points this week"
    }

    static func ordinal(_ n: Int) -> String {
        switch n {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(n)th"
        }
    }

    // MARK: - The two chips

    /// The water on the left, the day it settles on the right. Not a countdown:
    /// `PRODUCT.md` bans those, and "Monday" is the whole of what a student needs.
    private var chips: some View {
        VStack {
            HStack(alignment: .top) {
                chip {
                    TierPennant(tier: tier, earned: true, height: 19)
                    Text(tier.name).font(Theme.font(13, .black))
                }
                Spacer(minLength: 8)
                chip {
                    Text("Settles Monday").font(Theme.font(13, .black))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private func chip<V: View>(@ViewBuilder content: () -> V) -> some View {
        HStack(spacing: 6) { content() }
            .foregroundStyle(tier.edge)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Capsule().fill(.white.opacity(0.88)))
    }
}

/// A small gold crown for the winner's mound. Five points on a 26x20 grid.
struct CrownGlyph: View {
    var size: CGFloat = 26

    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 26
            var p = Path()
            p.move(to: CGPoint(x: 2 * s, y: 17 * s))
            p.addLine(to: CGPoint(x: 2 * s, y: 6 * s))
            p.addLine(to: CGPoint(x: 8 * s, y: 11 * s))
            p.addLine(to: CGPoint(x: 13 * s, y: 2 * s))
            p.addLine(to: CGPoint(x: 18 * s, y: 11 * s))
            p.addLine(to: CGPoint(x: 24 * s, y: 6 * s))
            p.addLine(to: CGPoint(x: 24 * s, y: 17 * s))
            p.closeSubpath()
            ctx.fill(p, with: .color(Theme.hex(0xE9B949)))
            ctx.stroke(p, with: .color(Theme.hex(0xB8861B)), style: StrokeStyle(lineWidth: 1.6 * s, lineJoin: .round))
        }
        .frame(width: size, height: size * 20 / 26)
        .accessibilityHidden(true)
    }
}
