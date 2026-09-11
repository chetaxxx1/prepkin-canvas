import SwiftUI

/// The season ladder, with a Free column and a Plus column.
///
/// Finch's monthly event is the conversion engine of that whole app, and this is
/// its shape: **both columns move on the same day, for the same reason.** Finishing
/// something real claims the day; the free column pays coins and the Plus column
/// hands over a costume as well. A student who never pays climbs every rung.
///
/// Three things it will not do, each from `PLUS-SPEC.md`:
///
/// - **No countdown.** "Ends Oct 12" is a date. A clock ticking down is the thing
///   section 9 bans, and a season is exactly where one would sneak back in.
/// - **No reset.** A missed day costs nothing, because a rung is claimed by count
///   and not by calendar position. The card says so out loud.
/// - **No padlock on the Plus column.** It is drawn in full colour with the word
///   Plus over it, the same way a coin item is drawn with its price.
struct SeasonCard: View {
    let season: Season

    @EnvironmentObject var state: AppState
    @State private var showingPlus = false
    @State private var justClaimed: GameState.SeasonPayout?

    private var progress: SeasonProgress { state.game.plus.progress(season) }
    private var verdict: SeasonClaim.Verdict {
        SeasonClaim.check(
            season: season,
            progress: progress,
            day: DayKey.today(),
            finishedToday: state.game.finishedToday()
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            head
            ladder.padding(.top, 14)
            claimRow.padding(.top, 14)
            Text("Miss a day and nothing changes. A claim is a claim.")
                .font(Theme.font(11, .heavy))
                .foregroundStyle(Theme.dim)
                .padding(.top, 10)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.card)
            .shadow(color: .black.opacity(0.05), radius: 11, y: 8))
        .sheet(isPresented: $showingPlus) { PlusSheet(reason: .look) }
        .sheet(item: $justClaimed) { payout in
            ClaimedSheet(payout: payout, season: season)
        }
    }

    private var head: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(season.name)
                    .font(Theme.font(17, .black))
                    .foregroundStyle(Theme.ink)
                Text("\(progress.rungsClaimed) of \(season.rungs.count) days claimed")
                    .font(Theme.font(12, .heavy))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            // A date, not a clock. Nothing here ticks.
            Text("Ends \(Self.endStamp(season))")
                .font(Theme.fixedFont(10.5, .black))
                .foregroundStyle(Theme.bagInk)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(Theme.paperSunk))
        }
    }

    /// The two columns. Claimed rungs are filled; the rest are outlines. Nothing is
    /// greyed out and nothing carries a lock.
    private var ladder: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("Free")
                    .font(Theme.fixedFont(9.5, .black))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 30, alignment: .leading)
                ForEach(Array(season.rungs.enumerated()), id: \.offset) { i, rung in
                    rungCell(rung.free, claimed: i < progress.rungsClaimed, plus: false)
                }
            }
            HStack(spacing: 6) {
                Text("Plus")
                    .font(Theme.fixedFont(9.5, .black))
                    .foregroundStyle(Theme.coralShade)
                    .frame(width: 30, alignment: .leading)
                ForEach(Array(season.rungs.enumerated()), id: \.offset) { i, rung in
                    rungCell(rung.plus,
                             claimed: state.isPlus && i < progress.rungsClaimed,
                             plus: true)
                }
            }
        }
    }

    @ViewBuilder
    private func rungCell(_ reward: Season.Reward, claimed: Bool, plus: Bool) -> some View {
        let tint = plus ? Theme.coral : Theme.coinDark
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(claimed ? (plus ? Theme.coralSoft : Theme.coinSoft) : Theme.paperSunk)
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(claimed ? tint : Theme.hairline, lineWidth: 1.5))
            switch reward {
            case .coins(let n):
                Text("\(n)")
                    .font(Theme.fixedFont(9.5, .black))
                    .foregroundStyle(claimed ? Theme.coinDark : Theme.dim)
            case .costume(let id):
                Text(Self.initials(id))
                    .font(Theme.fixedFont(9.5, .black))
                    .foregroundStyle(claimed ? Theme.coralShade : Theme.dim)
            }
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(Self.label(reward, claimed: claimed, plus: plus))
    }

    /// The button, and the reason when there is not one.
    @ViewBuilder
    private var claimRow: some View {
        switch verdict {
        case .ready:
            Button {
                guard let payout = state.claimSeasonRung(season) else { return }
                justClaimed = payout
            } label: {
                Text("Claim today")
                    .font(Theme.font(15, .heavy))
                    .foregroundStyle(Theme.onDarkWarm)
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
        case .nothingFinishedToday:
            note("Finish something today and the day is yours.")
        case .alreadyClaimedToday:
            note("Claimed today. The next one is tomorrow.")
        case .ladderFinished:
            note(state.isPlus
                 ? "Every day claimed, and the whole set is on your rack."
                 : "Every day claimed. Nice work.")
        case .outOfSeason:
            note("This one is over. The next season starts when the term does.")
        }

        if !state.isPlus {
            Button { showingPlus = true } label: {
                Text(season.headline.map { "The Plus track adds a costume a day, up to the \($0.name). In Plus." }
                     ?? "The Plus track adds a costume a day. In Plus.")
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(12.5, .heavy))
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Labels

    private static func initials(_ id: String) -> String {
        String((Costume.find(id)?.name ?? id).prefix(2)).uppercased()
    }

    private static func label(_ reward: Season.Reward, claimed: Bool, plus: Bool) -> String {
        let what: String
        switch reward {
        case .coins(let n): what = "\(n) coins"
        case .costume(let id): what = Costume.find(id)?.name ?? id
        }
        return "\(plus ? "Plus" : "Free"), \(what), \(claimed ? "claimed" : "not claimed yet")"
    }

    /// "Oct 12". Shared with the Kin tab's one-row Season entry.
    static func endStamp(_ season: Season) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: season.end.raw) else { return season.end.raw }
        return PlusGift.stamp(date)
    }
}

/// What a claim handed over. Reuses the costume put-on: the kin is drawn wearing
/// the thing it just got, at the size it is worn.
private struct ClaimedSheet: View {
    let payout: GameState.SeasonPayout
    let season: Season

    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var worn = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            KinArtView(
                speciesID: state.activeChibi.speciesID,
                level: 3,
                skin: payout.costume?.id ?? state.activeChibi.skinID,
                animation: .celebrate,
                size: 150
            )
            .scaleEffect(worn ? 1 : 0.86)
            .animation(.spring(response: 0.42, dampingFraction: 0.62), value: worn)

            Text("Day \(payout.rung + 1) of \(season.name)")
                .font(Theme.font(20, .black))
                .foregroundStyle(Theme.ink)

            VStack(spacing: 6) {
                if payout.coins > 0 {
                    HStack(spacing: 6) {
                        CoinDisc(size: 15)
                        Text("+\(payout.coins)")
                            .font(Theme.font(14, .heavy))
                            .foregroundStyle(Theme.coinDark)
                    }
                }
                if let costume = payout.costume {
                    Text("\(costume.name) is on your rack.")
                        .font(Theme.font(14, .heavy))
                        .foregroundStyle(Theme.muted)
                }
            }
            Spacer()
            Button("Done") { dismiss() }
                .font(Theme.font(17, .heavy))
                .foregroundStyle(Theme.onDarkWarm)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.coral))
                .buttonStyle(.plain)
        }
        .padding(24)
        .background(Theme.paper)
        .presentationDetents([.height(430)])
        .onAppear { worn = true }
    }
}

extension GameState.SeasonPayout: Identifiable {
    public var id: Int { rung }
}
