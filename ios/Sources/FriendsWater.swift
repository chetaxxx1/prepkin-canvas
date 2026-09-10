import SwiftUI

/// The Friends tab's hero: your kin standing on the floor of your league's water,
/// with an empty slot on each side of it.
///
/// The empty slots do the job three paragraphs used to do. A dashed ring where a
/// friend's kin would stand says "there is room here" without a sentence — the same
/// move as the blank signposts on Finch's friend tree. Nothing on this card is
/// invented: an empty slot is empty because the app has no friends in it, and when
/// friends arrive their kin stand in those slots and nothing else changes.
///
/// The water is the tier's own colour, so climbing the ladder is visible on the tab
/// that shows it rather than only inside the ladder screen.
struct FriendsWater: View {
    let tier: LeagueTier
    let speciesID: String
    let level: Int
    let skin: String
    /// Coins earned this week — the same number the ladder screen counts.
    let points: Int
    /// The friends to stand beside you. Empty on every real phone today.
    var friends: [Friend] = []
    /// Tapping an empty slot is the same as tapping Add a friend.
    var onEmptyTap: () -> Void = {}

    /// One slot each side of you. Two is what fits at this kin size without the row
    /// shrinking; the board and the list below carry everybody past that.
    private static let kinSize: CGFloat = 120
    private static let ringSize: CGFloat = 64

    /// Where every slot's feet land: far enough into the sand to stand on it rather
    /// than hover over it.
    private static let floor: CGFloat = 30
    private static let height: CGFloat = 300
    /// How much sand shows. The ellipse is far wider than the card so its crown reads
    /// as a gentle rise rather than a dome.
    private static let sandShown: CGFloat = 56

    var body: some View {
        ZStack(alignment: .bottom) {
            water
            sand
            weeds
            slots
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

    /// What a body resting on sand puts under itself. Without it every slot hovers.
    private var contactShadow: some View {
        Ellipse()
            .fill(Theme.hex(0xC9AE7E).opacity(0.32))
            .frame(width: 58, height: 11)
            .blur(radius: 3)
    }

    // MARK: - Who is standing in it

    private var slots: some View {
        HStack(alignment: .bottom, spacing: 18) {
            sideSlot(friend(at: 0))
            slot(caption: "You") {
                SproutImage(speciesID: speciesID, level: level, skin: skin,
                            size: Self.kinSize)
            }
            sideSlot(friend(at: 1))
        }
        .padding(.bottom, Self.floor)
    }

    /// You always stand in the middle, so a second friend arriving never shunts you
    /// to the edge of your own card.
    @ViewBuilder private func sideSlot(_ f: Friend?) -> some View {
        if let f {
            slot(caption: f.displayName) {
                SproutImage(speciesID: f.speciesID, level: f.level, skin: f.lookID, size: 84)
            }
        } else {
            emptySlot
        }
    }

    private func friend(at i: Int) -> Friend? {
        i < friends.count ? friends[i] : nil
    }

    private func slot<V: View>(caption: String, @ViewBuilder content: () -> V) -> some View {
        VStack(spacing: 5) {
            content()
                .background(alignment: .bottom) { contactShadow.offset(y: 4) }
            Text(caption)
                .font(Theme.font(12, .heavy))
                .foregroundStyle(tier.ink)
                .lineLimit(1)
        }
    }

    /// A place with nobody in it. Drawn the way an unowned kin is drawn everywhere
    /// else — full-strength colour, hollow rather than filled. Nothing greyed out,
    /// nothing padlocked, no "?".
    private var emptySlot: some View {
        Button(action: onEmptyTap) {
            VStack(spacing: 5) {
                ZStack {
                    Circle().fill(.white.opacity(0.30))
                    Circle().strokeBorder(tier.edge.opacity(0.34),
                                          style: StrokeStyle(lineWidth: 2, dash: [12, 9]))
                    Image(systemName: "plus")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(tier.edge.opacity(0.55))
                }
                .frame(width: Self.ringSize, height: Self.ringSize)
                .background(alignment: .bottom) {
                    contactShadow.frame(width: 42).offset(y: 5)
                }
                // Holds the caption's line so an empty slot's floor matches a kin's.
                Text(" ")
                    .font(Theme.font(12, .heavy))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Room for a friend. Add one.")
    }

    // MARK: - The two chips

    private var chips: some View {
        VStack {
            HStack(alignment: .top) {
                chip {
                    TierPennant(tier: tier, earned: true, height: 19)
                    Text(tier.name).font(Theme.font(13, .black))
                }
                Spacer(minLength: 8)
                chip {
                    CoinDisc(size: 13)
                    Text("\(points) this week").font(Theme.font(13, .black))
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
