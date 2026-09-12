import SwiftUI

/// The whole ladder on its own screen: the shelf, the water you are in, the six
/// waters, and the strangers pod.
///
/// Shaped after Dolphin SAT's Leaderboard (`design/reference/dolphin/02-my-league-bronze.png`):
/// a card for the water you are looking at, a stat strip under it, and a rail of
/// league tiles you scroll through. What Dolphin does that this app refuses is left
/// out — no promotion divider, no demotion zone, and no "Resets in 4d 8h" countdown,
/// which `PRODUCT.md` bans outright. Where Dolphin's rail is a trophy case you cannot
/// touch, ours is the navigation: tap any water and the card above shows it, so a
/// student can look at Deep in week one and see what it is rather than a padlock.
///
/// The Friends tab opens on the board; the rules live here, one tap away, for anyone
/// who wants them. The pod is drawn here always and on the tab once you have joined.
struct LeagueLadderView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    /// The water the card is showing. `nil` means the one you are actually in, so
    /// coming back to this screen never leaves you parked on somebody else's water.
    @State private var showing: LeagueTier?

    private var league: LeagueState { state.league }
    private var yours: LeagueTier { league.tier }
    private var selected: LeagueTier { showing ?? yours }
    private var points: Int { state.leaguePoints }

    private func earned(_ t: LeagueTier) -> Bool {
        t <= league.deepestReached && !t.isStart
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Text("The ladder")
                    .font(Theme.font(34, .black))
                    .kerning(-0.9)
                    .foregroundStyle(Theme.ink)
                    .frame(height: 40, alignment: .bottom)

                shelf.padding(.top, 18)

                waterCard.padding(.top, 14)

                Text("SIX WATERS")
                    .font(Theme.font(11.5, .black))
                    .kerning(0.9)
                    .foregroundStyle(Theme.dim)
                    .padding(.top, 24)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 4)

                rail

                PodSection()
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.card,
                                                 style: .continuous)
                        .fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card,
                                              style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 1))
                    .padding(.top, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, Theme.tabClearance)
        }
        .background(Theme.paper)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - The water you are looking at

    private var waterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                TierPennant(tier: selected, earned: earned(selected), height: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(selected.name)
                        .font(Theme.font(21, .black))
                        .kerning(-0.3)
                        .foregroundStyle(Theme.ink)
                    Text(selected.water)
                        .font(Theme.font(12.5, .semibold))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                if let pill = statePill {
                    Text(pill.0)
                        .font(Theme.font(10.5, .black))
                        .foregroundStyle(pill.1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(pill.2))
                        .fixedSize()
                }
            }

            if selected == yours {
                statStrip
                progress
            } else {
                Text(barLine)
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.sheet, style: .continuous)
            .fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.sheet, style: .continuous)
            .strokeBorder(Theme.hairline, lineWidth: 1))
        .animation(.easeOut(duration: 0.2), value: selected)
    }

    /// Three cells, Dolphin's shape, our numbers. Deliberately not their third cell:
    /// theirs counts down the hours left in the week, ours names the day the week
    /// settles and then stops talking.
    private var statStrip: some View {
        HStack(spacing: 0) {
            statCell(points.formatted(), "This week")
            divider
            statCell(LeagueRules.bar(for: yours)?.formatted() ?? "—", "Clears at")
            divider
            statCell(boardPlace, "On the board")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
            .fill(Theme.tile))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
            .strokeBorder(Theme.tileRing, lineWidth: 1))
    }

    /// Your place on this week's friends board. A dash with nobody else on it:
    /// first of one is not a place.
    private var boardPlace: String {
        let rows = state.weekBoard.rows
        guard rows.count >= 2, let mine = rows.first(where: { $0.member.isYou }) else { return "—" }
        return FriendsWater.ordinal(mine.place)
    }

    // MARK: - The shelf
    //
    // What the board has given you, kept. Four tiles, each a count that only goes
    // up. Drawn even at zero: a hollow pennant with a 0 under it says what a week
    // can win, the way an unowned kin in the shop says what a coin can buy.

    private var shelf: some View {
        HStack(spacing: 10) {
            shelfTile(league.weeksWon, "WEEKS WON") { MedalPennant(medal: 1, height: 30) }
            shelfTile(league.weeksSecond, "SECOND") { MedalPennant(medal: 2, height: 30) }
            shelfTile(league.weeksThird, "THIRD") { MedalPennant(medal: 3, height: 30) }
            shelfTile(league.questsCleared, "QUESTS") {
                ZStack {
                    PennantShape().fill(Theme.coral)
                    PennantFoldShape().fill(Theme.coralShade)
                    PennantShape().strokeBorder(Theme.coralShade, lineWidth: 1.4)
                }
                .frame(width: 30 * 40 / 56, height: 30)
                .accessibilityHidden(true)
            }
        }
    }

    private func shelfTile<V: View>(_ count: Int, _ label: String, @ViewBuilder glyph: () -> V) -> some View {
        VStack(spacing: 4) {
            glyph().opacity(count > 0 ? 1 : 0.35)
            Text("\(count)")
                .font(Theme.font(20, .black))
                .foregroundStyle(count > 0 ? Theme.ink : Theme.dim)
            Text(label)
                .font(Theme.font(10, .black))
                .kerning(0.5)
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label.lowercased())")
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.font(18, .black))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(Theme.font(11, .heavy))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var divider: some View {
        Rectangle().fill(Theme.tileRing).frame(width: 1, height: 30)
    }

    @ViewBuilder private var progress: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let toGo = state.leaguePointsToNextTier,
               let next = yours.next,
               let bar = LeagueRules.bar(for: yours) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hairline)
                        Capsule().fill(yours.color)
                            .frame(width: geo.size.width * min(1, Double(points) / Double(bar)))
                    }
                }
                .frame(height: 8)
                Text(toGo == 0
                     ? "That clears it. \(next.name) on Monday."
                     : "\(toGo) more and you're in \(next.name) on Monday. Winning the week on the board clears it too.")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Deep is the last one. Nothing below it, and nothing to lose.")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
            }
            Text("A quiet week keeps you where you are. Nothing here ever moves you down.")
                .font(Theme.font(11.5, .heavy))
                .foregroundStyle(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Text, ink, ground. `nil` for a water that is simply ahead of you — an empty
    /// corner says "not yet" without the app having to.
    private var statePill: (String, Color, Color)? {
        if selected == yours { return ("You're here", Theme.coralShade, Theme.coralSoft) }
        if earned(selected) { return ("Cleared", Theme.mintDark, Theme.mintSoft) }
        return nil
    }

    private var barLine: String {
        guard let bar = LeagueRules.bar(for: selected) else {
            return "The last water. There is no bar past it, and nothing below it to fall to."
        }
        if selected < yours {
            return "\(bar.formatted()) coins in a week left this water. You have already done it."
        }
        return "\(bar.formatted()) coins in a week leaves \(selected.name) for \(selected.next?.name ?? "the next water")."
    }

    // MARK: - The rail
    //
    // Duolingo's league rail (Mobbin aea875c3): every league's trophy in one row,
    // the one you are looking at big and in the middle, the ones you have earned in
    // colour, the ones ahead of you drawn but not lit. Theirs are padlocked and you
    // cannot touch them; ours are hollow, which is how an unowned kin is drawn in the
    // shop, and every one is the navigation — tap a water and the card above shows
    // it, so a student can look at Deep in week one and see what it is.

    private var rail: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 18) {
                    ForEach(LeagueTier.allCases) { tile($0).id($0) }
                }
                .padding(.horizontal, Theme.gutter + 4)
                .padding(.vertical, 6)
            }
            .scrollClipDisabled()
            .padding(.horizontal, -Theme.gutter)
            .onAppear { proxy.scrollTo(selected, anchor: .center) }
            .onChange(of: selected) { _, now in
                withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(now, anchor: .center) }
            }
        }
    }

    private func tile(_ t: LeagueTier) -> some View {
        let big = t == selected
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeOut(duration: 0.2)) { showing = t }
        } label: {
            VStack(spacing: 8) {
                TierPennant(tier: t, earned: earned(t) || t == yours, height: big ? 72 : 44)
                    .padding(big ? 14 : 8)
                    .background(Circle().fill(big ? t.color.opacity(0.16) : .clear))
                    .overlay(alignment: .topTrailing) {
                        if t == yours {
                            Circle().fill(Theme.coral)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                                .offset(x: big ? -8 : -2, y: big ? 8 : 2)
                        }
                    }
                Text(t.name)
                    .font(Theme.font(big ? 12.5 : 11, .heavy))
                    .foregroundStyle(big ? Theme.ink : Theme.muted)
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(minWidth: 64)
            .animation(.easeOut(duration: 0.2), value: big)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(t))
        .accessibilityAddTraits(t == selected ? [.isSelected] : [])
    }

    private func accessibilityLabel(_ t: LeagueTier) -> String {
        var s = t.name
        if t == yours { s += ", the water you're in" }
        else if earned(t) { s += ", cleared" }
        return s
    }
}
