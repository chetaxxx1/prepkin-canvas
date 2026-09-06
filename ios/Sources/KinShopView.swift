import SwiftUI

/// The shop, built on TFT's grammar of value and none of its grammar of loss.
///
/// Kept from TFT: a row of up to five slots, tier-coloured cost badges and plates,
/// and the lock. Refused: paying to reroll, a countdown to a refresh, exclusivity,
/// and odds you cannot check. A pick here is a 20% discount on something that is
/// also in the Collection at full price, forever — so rerolling can never cost you
/// a thing you wanted, which is why the reroll button carries no price at all.
struct KinShopView: View {
    /// The Kin tab pushes this screen, Home's coin chip presents it as a sheet.
    /// A sheet closes rather than goes back, so the caller says which it is instead
    /// of the screen guessing — the same body, wearing the control that tells the
    /// truth about where the tap lands.
    var asSheet = false

    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var detail: ChibiSpecies?
    @State private var showHonesty = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHead("Today's picks", trailing: "New picks tomorrow")
                    .padding(.top, 4)

                picksRow.padding(.top, 12)

                Text("Every pick is 20% off its Collection price. Press and hold a slot to keep its price.")
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.dim)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20).padding(.top, 12)

                if let held = state.lockedPick, let pick = state.game.resolvePick(held) {
                    heldPanel(pick).padding(.top, 12)
                }

                rerollButton.padding(.top, 14)

                if !state.rerollCanChange {
                    Text(rerollOffReason)
                        .font(Theme.font(10.5, .heavy))
                        .foregroundStyle(Theme.dim)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20).padding(.top, 8)
                }

                collectionEntry.padding(.top, 26)

                honestyEntry.padding(.top, 12)
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(Theme.paper)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .top) { navRow }
        .hidesTabBar()
        .kinToast(state.toast)
        .onAppear { state.refreshPicks() }
        .sheet(item: $detail) { species in
            KinDetailSheet(species: species)
                .presentationDetents([.fraction(0.78)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showHonesty) {
            HonestyPanel()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Chrome

    private var navRow: some View {
        HStack {
            Button { dismiss() } label: {
                // An x reads heavier than a chevron at the same point size, so it
                // steps down two points to keep both controls the same weight in
                // the same 38pt disc.
                Image(systemName: asSheet ? "xmark" : "chevron.left")
                    .font(.system(size: asSheet ? 13 : 15, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.card)
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 2))
                    .padding(3)
                    .contentShape(Rectangle())
                    .padding(-3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(asSheet ? "Close" : "Back")

            Spacer()
            Text("Shop").font(Theme.font(17, .black)).foregroundStyle(Theme.ink)
            Spacer()
            WalletChip(coins: state.coins, compact: true)
        }
        .padding(.horizontal, 20).padding(.bottom, 10)
        .background(Theme.paper)
    }

    private func sectionHead(_ title: String, trailing: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(Theme.font(18, .black)).foregroundStyle(Theme.ink)
            Spacer()
            Text(trailing).font(Theme.font(11.5, .heavy)).foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Picks

    private var picksRow: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(state.picks) { pick in
                PickSlot(pick: pick,
                         locked: state.lockedPick == pick.id,
                         gap: max(0, pick.price - state.coins))
                    .onTapGesture { open(pick) }
                    .onLongPressGesture {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        state.toggleLock(pick.id)
                    }
            }
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.34, dampingFraction: 0.74), value: state.picks)
    }

    private func heldPanel(_ pick: ShopPick) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(pick.name) is held at \(pick.price)")
                .font(Theme.font(13, .black)).foregroundStyle(Theme.ink)
            Text("A held slot keeps its discount through every reroll and overnight into tomorrow's picks. Long-press again to release it.")
                .font(Theme.font(12, .bold)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Theme.tier(pick.tier).opacity(0.16)))
        .padding(.horizontal, 20)
    }

    private var rerollNote: String {
        if !state.rerollCanChange { return "Nothing new to draw" }
        switch state.rerollsLeft {
        case 0: return "Back tomorrow"
        case 1: return "Free · 1 left today"
        default: return "Free · \(state.rerollsLeft) left today"
        }
    }

    /// Two different truths, and the empty one is reachable: every kin and every
    /// scene can be owned.
    private var rerollOffReason: String {
        state.picks.isEmpty
            ? "You own every kin and every scene. There is nothing left to draw."
            : "Every kin and scene you don't own is already in the row, so a reroll would only shuffle it."
    }

    /// Counted off the live row rather than spelled out. The row is only full while
    /// a reroll can change it, so this reads four today — but it can never drift
    /// away from the draw rule the way a hard-coded "four" did.
    private var rerollLabel: String {
        if state.rerolling { return "Rerolling…" }
        guard state.lockedPick != nil, state.rerollCanChange else { return "Reroll picks" }
        let others = max(0, state.picks.count - 1)
        return others == 1 ? "Reroll the other one" : "Reroll the other \(others)"
    }

    /// No cost badge on this control, ever. It is not disabled while it runs either —
    /// there is nothing to protect a double tap from. It *is* disabled once the row
    /// already holds everything unowned, because a draw that can only reshuffle
    /// would still spend one of the three.
    private var rerollButton: some View {
        Button { state.rerollPicks() } label: {
            HStack(spacing: 10) {
                KinIcon(.reroll, size: 20, color: state.rerolling ? Theme.dim : Theme.ink)
                    .rotationEffect(.degrees(state.rerolling ? 180 : 0))
                    .animation(.easeInOut(duration: 0.42), value: state.rerolling)
                Text(rerollLabel)
                    .font(Theme.font(15, .black))
                    .foregroundStyle(state.rerollsLeft == 0 || !state.rerollCanChange
                                     ? Theme.dim : Theme.ink)
                Spacer()
                Text(rerollNote)
                    .font(Theme.font(12, .heavy)).foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 18).padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 2)))
        }
        .buttonStyle(.plain)
        .disabled(!state.rerollCanChange)
        .padding(.horizontal, 20)
    }

    // MARK: Sections

    /// The nine kin and five scenes live in the Collection, one screen deeper, so
    /// this screen opens on the five picks alone: 21 cards at once became six
    /// (design/hicks-law-plan.md).
    private var collectionEntry: some View {
        NavigationLink { CollectionView() } label: {
            HStack(spacing: 10) {
                KinIcon(.dock, size: 19, color: Theme.ink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("See the whole collection").font(Theme.font(14, .black)).foregroundStyle(Theme.ink)
                    Text("\(state.owned.count) of \(ChibiSpecies.catalog.count) kin · \(state.ownedScenes.count) of \(Scene0.all.count) scenes, full price")
                        .font(Theme.font(11.5, .heavy)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .black)).foregroundStyle(Theme.dim)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.card))
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }

    private var honestyEntry: some View {
        Button { showHonesty = true } label: {
            HStack(spacing: 10) {
                KinIcon(.info, size: 19, color: Theme.muted)
                VStack(alignment: .leading, spacing: 2) {
                    Text("How the picks work").font(Theme.font(14, .black)).foregroundStyle(Theme.ink)
                    Text("Four things you can check against this screen.")
                        .font(Theme.font(11.5, .heavy)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .black)).foregroundStyle(Theme.dim)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.card))
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }

    private func open(_ pick: ShopPick) {
        switch pick.kind {
        case .kin(let species): detail = species
        case .scene(let scene):
            if state.ownedScenes.contains(scene.id) { state.equipScene(scene.id) }
            else { state.buyScene(scene) }
        }
    }
}

// MARK: - Slot

/// One slot in the row. A held slot reads by promotion — wider, lifted, white, ringed —
/// never by dimming the others into a wall.
private struct PickSlot: View {
    let pick: ShopPick
    let locked: Bool
    let gap: Int

    var body: some View {
        VStack(spacing: 5) {
            // One strip owns the top edge: the discount, or HELD while the slot is
            // held. Two pills used to share this edge and read "HELD 20%". The pin
            // is there in both states so the press-and-hold has something to point at.
            HStack(spacing: 3) {
                if locked {
                    KinIcon(.lock, size: 9, color: Theme.ink)
                } else {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 7.5, weight: .black))
                        .foregroundStyle(Theme.ink.opacity(0.55))
                }
                Text(locked ? "HELD" : "−20%")
                    .font(Theme.font(9.5, .black))
                    .foregroundStyle(Theme.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 17)
            .background(Theme.tier(pick.tier))

            Group {
                switch pick.kind {
                case .kin(let species):
                    KinArtView(speciesID: species.id, size: locked ? 60 : 54)
                        .frame(height: locked ? 54 : 49)
                case .scene(let scene):
                    Image(scene.asset)
                        .resizable().scaledToFill()
                        .frame(height: locked ? 54 : 49)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
            }
            .padding(.horizontal, 4)

            // One number. The full price is one screen deeper, in the Collection.
            KinCostBadge(price: pick.price, tier: pick.tier)

            if gap > 0 {
                Text("\(gap) to go")
                    .font(Theme.font(11, .heavy))
                    .foregroundStyle(Theme.coinDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)   // "785 to go" in a 70pt slot at 1.3× type
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Theme.coinSoft))
            }
        }
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(locked ? Theme.card : Theme.unowned))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Theme.tier(pick.tier), lineWidth: locked ? 2.5 : 2))
        .scaleEffect(locked ? 1.04 : 1, anchor: .bottom)
        .zIndex(locked ? 1 : 0)
    }
}

// MARK: - Scene card

struct SceneCard: View {
    let scene: Scene0
    let owned: Bool
    let equipped: Bool
    let price: Int
    let gap: Int
    let onUse: () -> Void
    let onBuy: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(scene.asset)
                .resizable().scaledToFill()
                .frame(height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(scene.name).font(Theme.font(15, .black)).foregroundStyle(Theme.ink)

            if equipped {
                Text("IN USE")
                    .font(Theme.font(10, .black)).foregroundStyle(Theme.mintDark)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Theme.mintSoft))
            } else if owned {
                Button(action: onUse) {
                    Text("Use").font(Theme.font(12, .heavy)).foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 5)
                        .background(Capsule().fill(Theme.coral))
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onBuy) {
                    HStack(spacing: 4) {
                        CoinDisc(size: 13)
                        Text("\(price)")
                    }
                    .font(Theme.font(12, .heavy)).foregroundStyle(Theme.coinDark)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Capsule().fill(Theme.coinSoft))
                }
                .buttonStyle(.plain)

                // Never disabled. A dimmed dead button is the greyed-out wall the
                // affordance panel already refuses; the tap answers with the number
                // instead. Mint rather than the picks row's coin, because this badge
                // sits directly under a coinSoft price pill and would read as a
                // second price.
                if gap > 0 {
                    Text("\(gap) to go")
                        .font(Theme.font(9.5, .heavy))
                        .foregroundStyle(Theme.mintDark)
                        .padding(.horizontal, 5).padding(.vertical, 1.5)
                        .background(Capsule().fill(Theme.mintSoft))
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(owned ? Theme.card : Theme.unowned)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2))
    }
}

// MARK: - Honesty panel

/// What TFT puts in an odds table, said in four claims a student can check against
/// the screen they just left.
struct HonestyPanel: View {
    @EnvironmentObject var state: AppState

    /// The slot count is read off the live row. This panel is the one place a student
    /// is invited to check us against the screen they just left, so it is the last
    /// place that can say "five" while four slots are showing.
    private var drawClaim: (String, String) {
        let slots = state.picks.count
        if slots == 0 {
            return ("Nothing left to draw",
                    "You own every kin and every scene. The row is empty because there is nothing left to offer at a discount.")
        }
        if !state.rerollCanChange {
            return ("\(slots) slot\(slots == 1 ? "" : "s"), all of what's left",
                    "Everything you don't own is already in the row. There are no weights and no rare slot.")
        }
        return ("\(slots) slots, drawn evenly",
                "Every kin and scene you don't own has exactly the same chance of showing up. There are no weights and no rare slot.")
    }

    private var claims: [(String, String)] {
        [drawClaim,
         ("A pick is a discount, not a prize",
          "Everything in the row is in the Collection too, at full price, always. A pick just takes 20% off."),
         ("Rerolling costs nothing, ever",
          "Three rerolls a day, no coins, no cooldown. You always end up with exactly the coins you started with."),
         ("Nothing ever leaves",
          "No timers, no seasons, no last chance. Anything you want today will still be here whenever you have the coins.")]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("How the picks work")
                    .font(Theme.font(25, .black)).foregroundStyle(Theme.ink)

                ForEach(claims, id: \.0) { claim in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(claim.0).font(Theme.font(15, .black)).foregroundStyle(Theme.ink)
                        Text(claim.1).font(Theme.font(12.5, .bold)).foregroundStyle(Theme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.card))
                }

                Text("Coins are earned by finishing things. Never by getting them right.")
                    .font(Theme.font(12, .heavy))
                    .foregroundStyle(Theme.dim)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(24)
        }
        .background(Theme.paper)
    }
}
