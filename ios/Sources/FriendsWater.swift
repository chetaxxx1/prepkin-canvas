import SwiftUI

/// The Friends tab's hero: this week's board, in your league's water, full bleed.
///
/// Three screens are copied here, on purpose and as closely as the art allows:
///
/// - **Finch, Tree Town** (`design/reference/finch/01-tree-town.png`): the tab *is* the
///   scene. It runs under the status bar, the pets stand in it, the empty places are
///   marked, and "Add friend" is a pill floating in the scene rather than a button
///   under it.
/// - **Transit, Top contributors** (Mobbin d1aa00b6): three on stands, the winner in
///   the middle and tallest, a 1st / 2nd / 3rd rosette under each face, everybody
///   else as a plain numbered list below.
/// - **Our own Reef Route** (`SwimSceneView`): the water, the sand, the kelp and the
///   corals are the same traced sprites the Focus shift swims through, so the tab
///   looks like the rest of the app's sea and not like a gradient with capsules in it.
///
/// Nothing on this card is invented. An empty stand is a dashed ring because nobody
/// is on it, and when a friend shares their week their kin lands there.
struct FriendsWater: View {
    let tier: LeagueTier
    /// The board, best first. Never empty: you are always on your own board.
    let rows: [BoardRow]
    /// The status bar's height, so the chips clear it while the water runs under it.
    var topInset: CGFloat = 0
    /// Tapping an empty stand, or the pill, is the same as tapping Add a friend.
    var onEmptyTap: () -> Void = {}
    /// Tapping a kin opens that person.
    var onTap: (BoardRow) -> Void = { _ in }

    private static let ringSize: CGFloat = 64
    /// The scene below the status bar. The sand takes the bottom fifth.
    private static let sceneHeight: CGFloat = 340
    private static let sandShown: CGFloat = 64
    /// Where every stand's foot lands: into the sand, not hovering over it.
    private static let floor: CGFloat = 22

    var body: some View {
        ZStack(alignment: .bottom) {
            water
            reef
            sand
            sandLife
            podium
            chips
            addPill
        }
        .frame(height: Self.sceneHeight + topInset)
        .frame(maxWidth: .infinity)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: Theme.Radius.sheet,
                                          bottomTrailingRadius: Theme.Radius.sheet, topTrailingRadius: 0,
                                          style: .continuous))
        .accessibilityElement(children: .contain)
    }

    // MARK: - The water

    private var water: some View {
        ZStack {
            LinearGradient(colors: [tier.color.opacity(0.42),
                                    tier.color.opacity(0.78),
                                    tier.color,
                                    tier.color],
                           startPoint: .top, endPoint: .bottom)
            // Light from the same corner as every other highlight in the app, and
            // two of the Reef Route's rays coming down through it.
            RadialGradient(colors: [.white.opacity(0.55), .white.opacity(0)],
                           center: UnitPoint(x: 0.22, y: -0.1),
                           startRadius: 0, endRadius: 260)
            rays
            bubbles
        }
        .background(Theme.card)
    }

    private var rays: some View {
        GeometryReader { geo in
            ray(at: 0.22, width: 30, alpha: 0.26, in: geo.size)
            ray(at: 0.62, width: 20, alpha: 0.16, in: geo.size)
        }
        .allowsHitTesting(false)
    }

    private func ray(at x: CGFloat, width w: CGFloat, alpha a: Double, in size: CGSize) -> some View {
        Path { p in
            let x0 = size.width * x
            p.move(to: CGPoint(x: x0, y: -20))
            p.addLine(to: CGPoint(x: x0 + w, y: -20))
            p.addLine(to: CGPoint(x: x0 - 70 + w * 0.5, y: size.height))
            p.addLine(to: CGPoint(x: x0 - 70 - w * 0.5, y: size.height))
            p.closeSubpath()
        }
        .fill(LinearGradient(colors: [.white.opacity(a), .white.opacity(0)],
                             startPoint: .top, endPoint: .bottom))
    }

    private var bubbles: some View {
        // Fixed positions rather than random: a card that redraws must not shuffle
        // its own background while somebody is reading it.
        ZStack {
            bubble(10, x: 0.27, y: 0.34)
            bubble(6, x: 0.33, y: 0.25)
            bubble(13, x: 0.76, y: 0.40)
            bubble(7, x: 0.83, y: 0.30)
            bubble(8, x: 0.50, y: 0.22)
        }
        .allowsHitTesting(false)
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

    // MARK: - The reef

    /// The far mounds and the kelp, from the Reef Route's own sprite sheet, planted
    /// where the swim scene plants them: far strip faint and low, tall kelp at the
    /// edges behind the stands, corals in front of the kelp and behind the sand line.
    private var reef: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let sandLine = geo.size.height - Self.sandShown
            let farH: CGFloat = 44
            Image("reef-far")
                .resizable()
                .frame(width: ReefSprites.width("far", height: farH), height: farH)
                .opacity(0.28)
                .position(x: w * 0.5, y: sandLine - farH / 2 + 6)
            sprite("plant-4", height: 118, x: 22, sandLine: sandLine)
            sprite("plant-1", height: 84, x: 48, sandLine: sandLine)
            sprite("coral-1", height: 40, x: 64, sandLine: sandLine)
            sprite("plant-4", height: 104, x: w - 20, sandLine: sandLine)
            sprite("plant-2", height: 72, x: w - 48, sandLine: sandLine)
            sprite("coral-3", height: 42, x: w - 66, sandLine: sandLine)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func sprite(_ name: String, height: CGFloat, x: CGFloat, sandLine: CGFloat) -> some View {
        let w = ReefSprites.width(name, height: height)
        // Rooted six points into the sand, exactly as `SwimSceneView.drawTile` roots them.
        return Image("reef-" + name)
            .resizable()
            .frame(width: w, height: height)
            .position(x: x, y: sandLine + 6 - height / 2)
    }

    /// The sea floor. A wide, shallow ellipse mostly below the card, so only its
    /// gentle crown shows and the stands have a line to sit on. The Reef Route's
    /// sand, with its lighter crest.
    private var sand: some View {
        GeometryReader { geo in
            let w = geo.size.width * 2.2
            let h: CGFloat = 150
            ZStack {
                Ellipse()
                    .fill(Reef.sand)
                    .overlay(Ellipse().strokeBorder(Reef.dune, lineWidth: 3.5))
                    .frame(width: w, height: h)
                Ellipse()
                    .fill(Reef.sandLight)
                    .frame(width: w - 8, height: h - 8)
                    .mask(Rectangle().frame(height: 12).offset(y: -h / 2 + 8))
            }
            .position(x: geo.size.width / 2,
                      y: geo.size.height - Self.sandShown + h / 2)
        }
        .allowsHitTesting(false)
    }

    /// A starfish on the sand, off to one side. One, because the shift's floor has
    /// one per tile and the tab is one tile wide.
    private var sandLife: some View {
        GeometryReader { geo in
            let h: CGFloat = 15
            Image("reef-star")
                .resizable()
                .frame(width: ReefSprites.width("star", height: h), height: h)
                .position(x: geo.size.width - 40, y: geo.size.height - 18)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - The stands

    /// Second on the left, first in the middle and tallest, third on the right.
    private var podium: some View {
        HStack(alignment: .bottom, spacing: 10) {
            stand(place: 2, row: row(at: 1), kin: 92, hill: 26)
            stand(place: 1, row: row(at: 0), kin: 116, hill: 40)
            stand(place: 3, row: row(at: 2), kin: 84, hill: 16)
        }
        .padding(.bottom, Self.floor)
    }

    private func row(at i: Int) -> BoardRow? { i < rows.count ? rows[i] : nil }

    /// The crown only when there is somebody to have beaten. A board of one has a
    /// fish in the middle and no crown over it, which is the truth.
    private var crowned: Bool { rows.count >= 2 }

    @ViewBuilder private func stand(place: Int, row: BoardRow?, kin: CGFloat, hill: CGFloat) -> some View {
        VStack(spacing: 0) {
            if let row {
                Button { onTap(row) } label: {
                    ZStack(alignment: .top) {
                        SproutImage(speciesID: row.member.speciesID, level: row.member.level,
                                    skin: row.member.lookID, size: kin)
                            .padding(.top, 14)
                            // What a body resting on sand puts under itself. Without
                            // it every kin hovers over its mound.
                            .background(alignment: .bottom) {
                                Ellipse()
                                    .fill(Theme.hex(0xC9AE7E).opacity(0.35))
                                    .frame(width: kin * 0.62, height: kin * 0.11)
                                    .blur(radius: 3)
                                    .offset(y: kin * 0.03)
                            }
                        if place == 1, crowned { BadgeMark(icon: "crown", height: 22) }
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
                .fill(Reef.sandLight)
                .overlay(Ellipse().strokeBorder(Reef.dune, lineWidth: 3))
                .frame(width: 104, height: (hill + 10) * 2)
                .frame(height: hill + 10, alignment: .top)
                .clipped()
                .zIndex(1)
            // Transit's rosette, as our medal: the metal under the face. Only with
            // somebody to have placed against — a board of one gets a name alone.
            VStack(spacing: 3) {
                if row != nil, crowned {
                    MedalPennant(medal: place, height: 26)
                        .offset(y: -10)
                        .padding(.bottom, -10)
                }
                HStack(spacing: 4) {
                    // A live desk, the same green dot the rows carry.
                    if let until = row?.member.onShiftUntil, until > Date() {
                        Circle().fill(Theme.mint).frame(width: 7, height: 7)
                    }
                    Text(row?.member.name ?? " ")
                        .font(Theme.font(12, .heavy))
                        .lineLimit(1)
                }
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

    // MARK: - The chips and the pill

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
            .padding(.top, topInset)
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

    /// Finch's "＋ Add friend" pill, floating in the scene at the bottom. The one
    /// action on the tab, always in the same place whether the board is empty or full.
    private var addPill: some View {
        HStack {
            Spacer(minLength: 0)
            Button(action: onEmptyTap) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Add a friend")
                        .font(Theme.font(13.5, .black))
                }
                .foregroundStyle(Theme.coral)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(Capsule().fill(.white)
                    .shadow(color: Theme.hex(0x281923).opacity(0.14), radius: 8, y: 3))
                // The pill draws at 36; the hit area is 44.
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add a friend")
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }
}
