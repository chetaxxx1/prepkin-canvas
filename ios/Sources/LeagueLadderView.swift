import SwiftUI

/// The whole ladder on its own screen, and the only place the pod lives.
///
/// Shaped after Dolphin SAT's Leaderboard (`design/reference/dolphin/02-my-league-bronze.png`):
/// a card for the water you are looking at, a stat strip under it, and a rail of
/// league tiles you scroll through. Everything Dolphin does that this app has already
/// refused is left out — no rank numeral, no promotion divider, no demotion zone, and
/// no "Resets in 4d 8h" countdown, which `PRODUCT.md` bans outright. Where Dolphin's
/// rail is a trophy case you cannot touch, ours is the navigation: tap any water and
/// the card above shows it, so a student can look at Deep in week one and see what it
/// is rather than a padlock.
///
/// This screen took the pod and the ladder off the Friends tab. That tab now opens on
/// a picture; the rules live here, one tap away, for anyone who wants them.
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

                waterCard.padding(.top, 18)

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
            statCell("Monday", "Settles")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
            .fill(Theme.tile))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
            .strokeBorder(Theme.tileRing, lineWidth: 1))
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
                     : "\(toGo) more and you're in \(next.name) on Monday.")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
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
    // Dolphin calls this League Progression and you cannot touch it. Here it is the
    // navigation: every water is tappable from week one, including the five above you.
    // Nothing is greyed, padlocked or hidden behind a "?" — an unearned pennant is
    // hollow, which is exactly how an unowned kin is drawn in the shop.

    private var rail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LeagueTier.allCases) { tile($0) }
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 3)
        }
        .scrollClipDisabled()
    }

    private func tile(_ t: LeagueTier) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeOut(duration: 0.2)) { showing = t }
        } label: {
            VStack(spacing: 7) {
                TierPennant(tier: t, earned: earned(t), height: 34)
                Text(t.name)
                    .font(Theme.font(11, .heavy))
                    .foregroundStyle(t == selected ? Theme.ink : Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 4)
            }
            .frame(width: 78, height: 94)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.tile(78), style: .continuous)
                .fill(t == selected ? t.color.opacity(0.18) : Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.tile(78), style: .continuous)
                .strokeBorder(t == selected ? t.edge : Theme.hairline,
                              lineWidth: t == selected ? 1.6 : 1))
            .overlay(alignment: .topTrailing) {
                if t == yours {
                    Circle().fill(Theme.coral)
                        .frame(width: 7, height: 7)
                        .padding(9)
                }
            }
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
