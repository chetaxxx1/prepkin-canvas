import SwiftUI

// The league, on screen. The rules live in `Core/LeagueState.swift`; this file is
// only how they look.
//
// The palette is deliberately not the kin-rarity ramp. Rarity is a hue wheel held at
// one lightness (every tier plate carries dark ink); the league is one hue arc that
// falls fifty-nine points of lightness, and the ink flips halfway down. You can tell
// a league colour from a rarity colour with the screen upside down, which is the
// whole point — a student must never read "Reef" as "this kin is rare".

extension LeagueTier {
    /// The cloth. Never used as text: below Kelp it measures 1.6:1 on a white card.
    var color: Color {
        switch self {
        case .tidepool:  return Theme.hex(0x8FDCCB)
        case .shallows:  return Theme.hex(0x4FBDC6)
        case .reef:      return Theme.hex(0x3A9FBF)
        case .kelp:      return Theme.hex(0x1F767E)
        case .openWater: return Theme.hex(0x1D5787)
        case .deep:      return Theme.hex(0x173A60)
        }
    }

    /// The fold and the keyline: same hue, twenty points of lightness down. Every one
    /// clears 3:1 on a white card, which is the only reason a Tidepool pennant has a
    /// silhouette at all.
    var edge: Color {
        switch self {
        case .tidepool:  return Theme.hex(0x3E9E8C)
        case .shallows:  return Theme.hex(0x2A8C95)
        case .reef:      return Theme.hex(0x226F8C)
        case .kelp:      return Theme.hex(0x0F4F55)
        case .openWater: return Theme.hex(0x123B5D)
        case .deep:      return Theme.hex(0x0E2440)
        }
    }

    /// Text laid directly on `color`. The flip at Kelp is forced, not stylistic:
    /// between those two lightnesses neither ink nor warm white reaches 4.5:1, so the
    /// ramp steps over that band. Worst ratio across all six is 4.86:1.
    var ink: Color { self <= .reef ? Theme.ink : Theme.onDarkWarm }
}

// MARK: - The pennant

/// A swallowtail pennant on a 40x56 grid. Spelled with raw `Path` calls because the
/// `go`/`to`/`bend` helpers are private to PrepkinIcons.swift.
struct PennantShape: InsettableShape {
    var inset: CGFloat = 0

    func path(in r: CGRect) -> Path {
        let b = r.insetBy(dx: inset, dy: inset)
        let s = min(b.width / 40, b.height / 56)
        let ox = b.minX + (b.width - 40 * s) / 2
        let oy = b.minY + (b.height - 56 * s) / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }

        var path = Path()
        path.move(to: p(3, 3))
        path.addLine(to: p(37, 3))
        path.addQuadCurve(to: p(30.5, 52), control: p(35.5, 30))
        path.addLine(to: p(20, 40))
        path.addLine(to: p(9.5, 52))
        path.addQuadCurve(to: p(3, 3), control: p(4.5, 30))
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> Self { var c = self; c.inset += amount; return c }
}

/// The shaded fly half. Two flat tones make cloth read as folded — the same trick the
/// open-book icon uses for its two covers.
struct PennantFoldShape: Shape {
    func path(in r: CGRect) -> Path {
        let s = min(r.width / 40, r.height / 56)
        let ox = r.minX + (r.width - 40 * s) / 2
        let oy = r.minY + (r.height - 56 * s) / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }

        var path = Path()
        path.move(to: p(21.5, 3))
        path.addLine(to: p(37, 3))
        path.addQuadCurve(to: p(30.5, 52), control: p(35.5, 30))
        path.addLine(to: p(20, 40))
        path.closeSubpath()
        return path
    }
}

/// The keepsake. One per tier reached, kept forever.
///
/// Not-yet-earned is drawn the way an unowned kin is drawn: full-strength tier colour,
/// hollow instead of filled. Nothing is greyed, blurred, padlocked or silhouetted, and
/// the caller always shows the condition beside it.
struct TierPennant: View {
    let tier: LeagueTier
    var earned: Bool
    var height: CGFloat = 56

    private var width: CGFloat { height * 40 / 56 }
    private var line: CGFloat { max(1.4, height * 0.045) }

    var body: some View {
        ZStack {
            if earned {
                PennantShape().fill(tier.color)
                PennantFoldShape().fill(tier.edge)
            } else {
                PennantShape().fill(Theme.unowned)
            }
            PennantShape().strokeBorder(tier.edge, lineWidth: line)
        }
        .frame(width: width, height: height)
        .accessibilityElement()
        .accessibilityLabel(earned ? "\(tier.name) pennant, yours" : "\(tier.name) pennant, not yet")
    }
}

/// Names the current tier inline. A white pill with a coloured object in it — the same
/// shape the coin chip is, so it sits beside it instead of competing with it.
struct TierBadge: View {
    let tier: LeagueTier
    var onScene = false

    var body: some View {
        HStack(spacing: 5) {
            TierPennant(tier: tier, earned: true, height: 17)
            Text(tier.name)
                .font(Theme.font(11, .black))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.leading, 9).padding(.trailing, 11)
        .padding(.vertical, onScene ? 9 : 6)
        .background(
            Capsule()
                .fill(onScene ? Color.white.opacity(0.95) : Theme.card)
                .shadow(color: Theme.hex(0x281923).opacity(onScene ? 0.16 : 0.08),
                        radius: onScene ? 6 : 8, y: onScene ? 3 : 2)
        )
        .overlay(Capsule().strokeBorder(tier.edge, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("League: \(tier.name)")
    }
}

// MARK: - The ladder

/// The six tiers as a column of water, shallowest at the top. Nothing has a fixed
/// width except the pennant lane, because a fixed-width row is exactly what pushed the
/// Kin tab off screen once already.
struct TierLadder: View {
    let current: LeagueTier
    let deepest: LeagueTier
    /// Short line against the tier below the deepest one reached — "60 to go".
    var nextNote: String?

    private static let rowH: CGFloat = 44
    private static let lane: CGFloat = 24

    var body: some View {
        VStack(spacing: 0) {
            ForEach(LeagueTier.allCases) { row($0) }
        }
        .background(alignment: .topLeading) { rail }
    }

    private func row(_ t: LeagueTier) -> some View {
        HStack(spacing: 12) {
            TierPennant(tier: t, earned: t <= deepest && !t.isStart, height: Self.lane)
                .frame(width: Self.lane)
            Text(t.name)
                .font(Theme.font(15, .black))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .layoutPriority(1)
            Spacer(minLength: 8)
            if let s = status(t) {
                Text(s)
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(t == current ? Theme.ink : Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, t == current ? 9 : 0)
                    .padding(.vertical, t == current ? 3 : 0)
                    .background(Capsule().fill(t == current ? t.color.opacity(0.3) : .clear))
            }
        }
        .padding(.horizontal, 6)
        .frame(height: Self.rowH)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(t == current ? t.color.opacity(0.14) : .clear))
        .accessibilityElement(children: .combine)
    }

    private func status(_ t: LeagueTier) -> String? {
        if t == current { return "You're here" }
        if t <= deepest && !t.isStart { return "Reached" }
        if t.rawValue == current.rawValue + 1 { return nextNote }
        return nil
    }

    /// One track through the pennant centres. Filled to where the student is now.
    private var rail: some View {
        ZStack(alignment: .top) {
            Capsule().fill(Theme.hairline)
                .frame(width: 5, height: CGFloat(LeagueTier.allCases.count - 1) * Self.rowH)
            Capsule().fill(current.color)
                .frame(width: 5, height: CGFloat(current.rawValue) * Self.rowH)
        }
        .padding(.leading, 6 + Self.lane / 2 - 2.5)
        .padding(.top, Self.rowH / 2)
    }
}

extension LeagueTier {
    /// Tidepool is where everyone starts, so there is no pennant for it — a keepsake
    /// handed out for existing is worth nothing next to a track badge, which means
    /// eight finished lessons.
    var isStart: Bool { self == .tidepool }
}

// MARK: - The pod

/// The pod, and only the pod. It sits inside `LeagueLadderView`.
///
/// This was `LeagueCard`, which drew the tier, the progress bar, the pod and a
/// fold-out ladder in one 620pt block at the top of the Friends tab. The tier and the
/// ladder moved to `LeagueLadderView`; what is left is the part that was always its
/// own thing.
///
/// When the pod holds nobody but you it says so plainly. The alternative — inventing
/// nineteen rivals so the board looks busy — is the same dishonesty as the four
/// hard-coded friends that were cut from this tab, moved one screen over.
struct PodSection: View {
    @EnvironmentObject var state: AppState

    private var points: Int { state.leaguePoints }

    var body: some View {
        podSection
            .frame(maxWidth: .infinity, alignment: .leading)
            // A no-op unless the student opted in, so a card on screen never mints a
            // row on the bridge. Nothing else in the app asks for the board yet.
            .task { await state.syncLeague() }
    }

    // MARK: - The pod
    //
    // Strangers in the same water, for one week. The rules are in `LeagueSync.swift`
    // and `AppState.syncLeague`; this is only what they look like.
    //
    // Three states and no fourth: not opted in, opted in with nobody else yet, and
    // opted in with people. There is deliberately no state that draws somebody who is
    // not really there. Four hard-coded friends were cut from this tab for exactly
    // that, so a pod of one says "you're the first one here" instead of filling up.

    private enum Confirm { case leave, forget }
    @State private var confirm: Confirm?
    /// True while a join, a leave or an erase is in the air, so the control that
    /// started it cannot be tapped a second time on top of the first.
    @State private var working = false

    /// The most rows drawn at once. A pod holds up to twenty, and twenty rows inside a
    /// card on the Friends tab is a wall — so the board draws the top of the pod and
    /// the count line below says how many are not shown. Your own row is pinned on top
    /// of this, never counted against it.
    private static let rowsShown = 8

    /// A name the shipped word lists can really produce, used as the example in the
    /// offer. Built rather than typed, so it cannot drift from `podnames.json`.
    private var exampleName: String { PodName.name(adjective: 0, noun: 0) }

    @ViewBuilder private var podSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if state.podOptIn {
                if let pod = state.pod, !pod.members.isEmpty {
                    podBoard(pod)
                } else {
                    waiting
                }
                if let note = state.leagueStatus { statusLine(note) }
                podExits
            } else {
                podOffer
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Opted out — the default

    /// What a student sees before they have agreed to anything, which is most of them
    /// forever. The four things are listed as four things on purpose: they are exactly
    /// the four fields a `PodMember` carries, so somebody can read this line, look at a
    /// row, and find nothing extra in it.
    private var podOffer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Swim with a pod")
                .font(Theme.font(15, .black))
                .foregroundStyle(Theme.ink)

            Text("Twenty students, one week, nobody knows anybody. They would see four things:")
                .font(Theme.font(12.5, .bold))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            // Four rows because a `PodMember` carries exactly four fields, so a
            // student can hold this list against any row on the board and find
            // nothing extra. The sentence under it is the promise itself, kept
            // word for word: icons can say what is shared, they cannot say what
            // is impossible.
            VStack(spacing: 0) {
                offerRow("Your kin") { SproutFace(speciesID: state.activeChibiID, size: 24) }
                offerRow("Its stars") { StarPips(level: state.activeChibi.level, size: 9, spacing: 2.5) }
                offerRow("A name this app picks") {
                    Text(exampleName).font(Theme.font(12.5, .black)).foregroundStyle(Theme.ink)
                }
                offerRow("Coins you earned this week", last: true) {
                    HStack(spacing: 4) {
                        CoinDisc(size: 11)
                        Text("\(points)").font(Theme.font(12.5, .black)).foregroundStyle(Theme.ink)
                    }
                }
            }
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.tile))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.tileRing, lineWidth: 1))

            Text("Nothing else, and nothing you typed. There is nowhere in this app to type a name.")
                .font(Theme.font(12.5, .bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                working = true
                Task { @MainActor in
                    await state.joinLeaguePod()
                    working = false
                }
            } label: {
                Text(working ? "Joining" : "Join a pod")
                    .font(Theme.font(15, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Theme.coral)
                        .shadow(color: Theme.coral.opacity(working ? 0 : 0.28), radius: 12, y: 5))
                    .opacity(working ? 0.5 : 1)
            }
            .buttonStyle(.plain)
            .disabled(working)
            .padding(.top, 2)
        }
    }

    private func offerRow<V: View>(_ label: String, last: Bool = false,
                                   @ViewBuilder value: () -> V) -> some View {
        HStack(spacing: 10) {
            Text(label).font(Theme.font(12.5, .bold)).foregroundStyle(Theme.muted)
            Spacer(minLength: 8)
            value()
        }
        .frame(minHeight: 40)
        .overlay(alignment: .bottom) {
            if !last { Rectangle().fill(Theme.tileRing).frame(height: 1) }
        }
    }

    // MARK: Opted in, nothing back yet

    /// Opted in, nothing back yet. Two readings of the same state, because saying
    /// "You're in" directly above "Could not reach the pod" reads as a contradiction
    /// and makes the student wonder which half is the lie.
    private var waiting: some View {
        let reached = state.leagueStatus == nil
        return VStack(alignment: .leading, spacing: 6) {
            Text(reached ? "Looking for a pod" : "No pod yet")
                .font(Theme.font(15, .black))
                .foregroundStyle(Theme.ink)
            Text(reached
                 ? "You're in. The board fills in as soon as the pod answers, and nobody lands on it who is not really there."
                 : "You're opted in, but the pod hasn't answered yet. Nothing is lost — your tier, your pennants and your coins are all on this phone.")
                .font(Theme.font(12.5, .bold))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Opted in, with a board

    private func podBoard(_ pod: PodSnapshot) -> some View {
        let rows = drawn(pod)
        let hidden = pod.members.count - rows.count
        let bar = LeagueRules.bar(for: pod.tier)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Your pod")
                    .font(Theme.font(15, .black))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 4)
                Text(pod.isAlone ? "Just you so far" : "\(pod.members.count) in the water")
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.dim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            VStack(spacing: 2) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { i, member in
                    // A pinned row that is not next in the order gets a rule above it,
                    // so it can never read as if you finished behind the person drawn
                    // directly above you.
                    if i > 0, member.rank != rows[i - 1].rank + 1 {
                        Rectangle().fill(Theme.hairline)
                            .frame(height: 1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                    }
                    PodRow(member: member, tier: pod.tier, bar: bar)
                }
            }

            if pod.isAlone {
                Text("You're the first one here. Whoever joins this water next lands beside you. Nobody is ever added to make the list look busier.")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if hidden > 0 {
                Text(hidden == 1
                     ? "One more person is in this pod, below what's drawn."
                     : "\(hidden) more people are in this pod, below what's drawn.")
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(bar == nil
                 ? "Deep is the last water, so there is no bar left to clear. This is company, not a race — nothing in a pod ever moves anybody down."
                 : "A pennant means that person has already cleared this week's bar. Everyone who clears it moves up on Monday, and nobody here ever moves down.")
                .font(Theme.font(11.5, .heavy))
                .foregroundStyle(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The rows to draw: the top of the board, plus your own row pinned on when you
    /// finished below the cut. The order the bridge sent is never re-sorted here.
    private func drawn(_ pod: PodSnapshot) -> [PodMember] {
        let head = Array(pod.members.prefix(Self.rowsShown))
        guard let you = pod.you, !head.contains(where: { $0.isYou }) else { return head }
        return head + [you]
    }

    private func statusLine(_ note: String) -> some View {
        Text(note)
            .font(Theme.font(11.5, .heavy))
            .foregroundStyle(Theme.dim)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: The two ways out

    /// Leave and erase are different things and are worded as different things. Leave
    /// keeps the identity so coming back on Monday re-uses this phone's row instead of
    /// minting a second one; erase deletes the row outright. Both say what stays.
    @ViewBuilder private var podExits: some View {
        if confirm == .leave {
            confirmBlock("Leaving takes your kin off the board and turns pods back off. Your tier, your pennants and your coins all stay exactly where they are.",
                         verb: "Leave", leaving: true)
        } else if confirm == .forget {
            confirmBlock("Erasing deletes your row from the pod: the name it gave you, the kin on the board and this week's number. Your tier, your pennants and your coins stay here on this phone.",
                         verb: "Erase", leaving: false)
        } else {
            HStack(spacing: 16) {
                Button { confirm = .leave } label: {
                    Text("Leave the pod")
                        .font(Theme.font(13, .heavy))
                        .foregroundStyle(Theme.coralDeep)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .buttonStyle(.plain)

                Button { confirm = .forget } label: {
                    Text("Erase me from the pod")
                        .font(Theme.font(13, .heavy))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .disabled(working)
            .opacity(working ? 0.5 : 1)
        }
    }

    private func confirmBlock(_ question: String, verb: String, leaving: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question)
                .font(Theme.font(12.5, .bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button {
                    confirm = nil
                    working = true
                    Task { @MainActor in
                        if leaving {
                            await state.leaveLeaguePod()
                        } else {
                            await state.forgetLeaguePlayer()
                        }
                        working = false
                    }
                } label: {
                    Text(verb)
                        .font(Theme.font(13, .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Theme.coral))
                }
                .buttonStyle(.plain)

                Button { confirm = nil } label: {
                    Text("Never mind")
                        .font(Theme.font(13, .heavy))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Theme.tile))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Theme.tileRing, lineWidth: 1))
    }
}

// MARK: - One person in the pod

/// A pod member, drawn the way a kin is drawn everywhere else in the app.
///
/// There is no rank numeral. The order is the ranking, and a number stamped beside
/// somebody's face is the thing this tab has refused since it was built — see the
/// header of `FriendsView`. There is no demotion zone either, and no marker for being
/// low: the only mark on this row is a pennant for a bar already cleared, which is a
/// thing that can appear and never a thing that can be taken away.
private struct PodRow: View {
    let member: PodMember
    /// The water the whole pod is in. Every member shares it, which is the only reason
    /// comparing their coins means anything.
    let tier: LeagueTier
    /// Coins that clear this tier's bar, or `nil` at Deep — where there is nothing
    /// above to charge for, so no row is marked at all.
    let bar: Int?

    private var clears: Bool {
        guard let bar else { return false }
        return member.points >= bar
    }

    var body: some View {
        HStack(spacing: 10) {
            // `member.lookID` is not drawn: `SproutFace` takes a species and nothing
            // else. Drawing a pod member through the same component as every other
            // face in the app matters more here than the coat does — and the offer
            // above promises the kin and its stars, not its outfit.
            SproutFace(speciesID: member.speciesID, size: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(Theme.font(14, member.isYou ? .black : .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                StarPips(level: member.level, size: 8.5, spacing: 2.5)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            if member.isYou {
                Text("You")
                    .font(Theme.font(9.5, .black))
                    .foregroundStyle(Theme.coralShade)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Theme.coralSoft))
                    .fixedSize()
            }

            if clears {
                TierPennant(tier: tier, earned: true, height: 15)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 3) {
                CoinDisc(size: 12)
                Text("\(member.points)")
                    .font(Theme.font(13, .black))
                    .foregroundStyle(Theme.coinDark)
                    .lineLimit(1)
            }
            .fixedSize()
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 44)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(member.isYou ? Theme.paper : .clear))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }

    private var label: String {
        var parts = [member.isYou ? "\(member.displayName), you" : member.displayName]
        parts.append(member.level == 1 ? "1 star" : "\(member.level) stars")
        parts.append("\(member.points) coins this week")
        if clears { parts.append("this week's bar cleared") }
        return parts.joined(separator: ", ")
    }
}
