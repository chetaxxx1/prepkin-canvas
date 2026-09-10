import SwiftUI

/// The shop, built on TFT's grammar of value and none of its grammar of loss.
///
/// Kept from TFT: a drawn row that rerolls, tier colour, and the hold. Refused:
/// paying to reroll, a countdown to a refresh, exclusivity, and odds you cannot
/// check. A pick here is a discount — 20%, or 30% on Plus — on something that is
/// also in the Collection at full price, forever — so rerolling can never cost you
/// a thing you wanted, which is why the reroll button carries no price at all.
///
/// **The 2026-09-10 rebuild.** The row used to be five 68pt slots, so the art — the
/// only thing anybody is here to look at — rendered at 54pt behind a border, a
/// colour strip, a price pill and a "320 to go" pill. Chrome outweighed product,
/// five identical rejections stacked across the screen, and the bottom 60% was
/// empty. Now one pick is the hero at full width over a 176pt band of art, the rest
/// sit in a two-up grid over 112pt, and the shortfall is told **once**, on the hero,
/// as a bar filling toward a number rather than five pills counting what you lack.
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
    @State private var showingPlus = false

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header.padding(.top, 2)

                if state.picks.isEmpty {
                    soldOutPanel.padding(.top, 16)
                } else {
                    if let hero = heroPick {
                        FeaturedPick(pick: hero,
                                     held: state.isHeld(hero.id),
                                     coins: state.coins,
                                     work: state.workToAfford(hero.id))
                            .padding(.horizontal, 20).padding(.top, 14)
                            .onTapGesture { open(hero) }
                            .onLongPressGesture { hold(hero) }
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(restOfPicks) { pick in
                            PickCard(pick: pick,
                                     held: state.isHeld(pick.id),
                                     affordable: pick.price <= state.coins)
                                .onTapGesture { open(pick) }
                                .onLongPressGesture { hold(pick) }
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 12)
                    .animation(.spring(response: 0.34, dampingFraction: 0.74), value: state.picks)

                    if let held = heldNote {
                        Text(held)
                            .font(Theme.font(11.5, .heavy))
                            .foregroundStyle(Theme.dim)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20).padding(.top, 12)
                    }

                    rerollButton.padding(.top, 16)

                    if !state.rerollCanChange {
                        Text(rerollOffReason)
                            .font(Theme.font(10.5, .heavy))
                            .foregroundStyle(Theme.dim)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20).padding(.top, 8)
                    }

                    plusRow.padding(.top, 12)
                }

                collectionEntry.padding(.top, 24)

                honestyEntry.padding(.top, 10)
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(Theme.paper)
        .sheet(isPresented: $showingPlus) { PlusSheet(reason: .shop) }
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

    /// The discount is said once, here, instead of stamped on every card. Every pick
    /// is off by the same percent, so five −20% tags were five copies of one fact;
    /// the cards carry the struck-through Collection price instead, which is the part
    /// that actually differs item to item.
    /// Both lines go quiet once the row is empty. A screen with nothing on it used to
    /// still promise "everything here is 20% off" and "new picks tomorrow" — two
    /// sentences about merchandise that does not exist, over a card explaining that
    /// it never will again.
    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today's picks").font(Theme.font(22, .black)).foregroundStyle(Theme.ink)
                Spacer()
                if !state.picks.isEmpty {
                    Text("New picks tomorrow")
                        .font(Theme.font(11.5, .heavy)).foregroundStyle(Theme.muted)
                }
            }
            if !state.picks.isEmpty {
                Text("Everything here is \(state.pickDiscountPercent)% off. Press and hold one to keep its price.")
                    .font(Theme.font(12, .heavy)).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Picks

    /// Which pick gets the big card. A held pick first, because holding one is the
    /// student saying out loud that this is the one they want. Otherwise the best
    /// thing today's coins can actually buy — a shop should open on something you can
    /// take home. If nothing is affordable, the *closest* one leads, so the bar under
    /// it is a target rather than a wall.
    private var heroPick: ShopPick? {
        let picks = state.picks
        if let held = picks.filter({ state.isHeld($0.id) }).max(by: { $0.price < $1.price }) {
            return held
        }
        if let best = picks.filter({ $0.price <= state.coins }).max(by: { $0.price < $1.price }) {
            return best
        }
        return picks.min(by: { $0.price < $1.price })
    }

    private var restOfPicks: [ShopPick] {
        guard let hero = heroPick else { return state.picks }
        return state.picks.filter { $0.id != hero.id }
    }

    private func hold(_ pick: ShopPick) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        state.toggleLock(pick.id)
    }

    /// One line for every held slot, instead of a stacked explainer panel each. The
    /// rule is the same for all of them, so it is stated once.
    private var heldNote: String? {
        let held = state.picks.filter { state.isHeld($0.id) }
        guard !held.isEmpty else { return nil }
        let names = held.map(\.name).joined(separator: ", ")
        let verb = held.count == 1 ? "is" : "are"
        return "\(names) \(verb) held. A held price survives every reroll and tonight's redraw. Press and hold again to let go."
    }

    // MARK: Reroll

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
        guard !state.lockedPicks.isEmpty, state.rerollCanChange else { return "Reroll picks" }
        let others = max(0, state.picks.count - state.lockedPicks.count)
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

    // MARK: Plus

    /// A plain row, never a coral one. Coral is the primary action on every screen
    /// and Plus is never the primary action (`PLUS-SPEC.md` section 4).
    ///
    /// Already Plus? Then it says what the row is doing rather than selling it
    /// again. Nothing here is a padlock and nothing is greyed out — the numbers
    /// a free student has are the numbers on their screen, and these are the other
    /// ones, in plain text.
    @ViewBuilder
    private var plusRow: some View {
        if state.isPlus {
            Text("Seven picks, three holds, \(state.pickDiscountPercent)% off. Thanks for the Plus.")
                .font(Theme.font(11.5, .heavy))
                .foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
        } else {
            Button { showingPlus = true } label: {
                HStack(spacing: 10) {
                    // Reroll, Collection and How-the-picks-work all open with a 19pt
                    // mark, so this row's text used to start in a column of its own.
                    Spark().fill(Theme.dim)
                        .frame(width: 17, height: 17)
                        .frame(width: 19)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Seven picks, three holds, 30% off")
                            .font(Theme.font(14, .black)).foregroundStyle(Theme.ink)
                        Text("In Plus")
                            .font(Theme.font(11.5, .heavy)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(Theme.dim)
                }
                .padding(.horizontal, 18).padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 2)))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .accessibilityLabel("Seven picks, three holds, 30 percent off. In Plus.")
        }
    }

    // MARK: Sections

    /// Owning everything used to leave a blank screen under a dead reroll button.
    /// It is the end of the game, so it gets a card that says so.
    private var soldOutPanel: some View {
        VStack(spacing: 8) {
            // Drawn, not 🎉. An emoji renders in the system font, which is the one
            // thing on a Prepkin screen that is not in the palette (`Spark`).
            HStack(spacing: 6) {
                Spark().fill(Theme.coin).frame(width: 14, height: 14)
                Spark().fill(Theme.coin).frame(width: 26, height: 26)
                Spark().fill(Theme.coin).frame(width: 14, height: 14)
            }
            .padding(.bottom, 4)
            Text("You own all of it")
                .font(Theme.font(19, .black)).foregroundStyle(Theme.ink)
            Text("Every kin and every scene is yours. There is nothing left for the shop to put on sale — spend what you earn on stars instead.")
                .font(Theme.font(12.5, .bold)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.card))
        .padding(.horizontal, 20)
    }

    /// The nine kin and five scenes live in the Collection, one screen deeper, so
    /// this screen opens on the picks alone: 21 cards at once became six
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

// MARK: - Featured pick

/// The one big card. Everything the old 68pt slot could only gesture at gets said
/// here at full size: the art, the name, what it costs, what it used to cost, and —
/// for exactly one item on the screen — how far off you are and what closes the gap.
private struct FeaturedPick: View {
    let pick: ShopPick
    let held: Bool
    let coins: Int
    /// `GameState.workToAfford` in plain English — "That's 2 more assignments
    /// finished." Nil once you can afford it.
    let work: String?

    private var gap: Int { max(0, pick.price - coins) }
    private var tint: Color { Theme.tier(pick.tier) }

    var body: some View {
        VStack(spacing: 0) {
            art
            details
        }
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
            .strokeBorder(held ? tint : Theme.cardEdge, lineWidth: held ? 3 : 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 16, y: 6)
        .accessibilityElement(children: .combine)
    }

    // MARK: Art

    /// A kin stands on a wash of its tier colour; a scene *is* the wash, bled to all
    /// four edges. Two different shapes of thing, so two different treatments — the
    /// old row cropped a wide painting into a 60pt square and showed the middle
    /// fifth of it.
    ///
    /// The art is asked for at 196 to fill a 176pt band, not 176: `SproutImage` crops
    /// its square to `size × 0.7` and a stage-I kin only paints part of that again, so
    /// a number that matches the band leaves the character floating in a third of it.
    /// 196 is the detail sheet's 180 plus the crop, and it is bottom-aligned so the
    /// kin stands on the card instead of hovering in the middle of it.
    private var art: some View {
        ZStack(alignment: .topLeading) {
            switch pick.kind {
            case .kin(let species):
                LinearGradient(colors: [tint.opacity(0.42), tint.opacity(0.12)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 176)
                    .overlay(alignment: .bottom) {
                        KinArtView(speciesID: species.id, size: 196)
                            .padding(.bottom, 6)
                    }
            case .scene(let scene):
                Image(scene.asset)
                    .resizable().scaledToFill()
                    .frame(height: 176)
                    .clipped()
            }

            tag
                .padding(12)
        }
        .frame(height: 176)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var tag: some View {
        HStack(spacing: 4) {
            if held {
                KinIcon(.lock, size: 9, color: Theme.ink)
                Text("HELD AT THIS PRICE")
            } else {
                Text(kindLabel)
            }
        }
        .font(Theme.font(9.5, .black))
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(held ? tint : Theme.card.opacity(0.92)))
    }

    private var kindLabel: String {
        switch pick.kind {
        case .kin: return "\(Theme.tierName(pick.tier)) KIN"
        case .scene: return "SCENE"
        }
    }

    // MARK: Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(pick.name)
                    .font(Theme.font(21, .black)).foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 10)
                priceStack
            }

            if gap > 0 { shortfall } else { buyButton }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Today's price large, the Collection price struck through beside it. This is the
    /// only place the discount is shown as money rather than a percent, which is the
    /// form a student can check: 400 becomes 320.
    private var priceStack: some View {
        VStack(alignment: .trailing, spacing: 1) {
            HStack(spacing: 5) {
                CoinDisc(size: 17)
                Text("\(pick.price)")
                    .font(Theme.font(23, .black)).foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            Text("\(pick.fullPrice)")
                .font(Theme.font(12, .heavy)).foregroundStyle(Theme.dim)
                .strikethrough()
        }
    }

    private var buyButton: some View {
        HStack(spacing: 7) {
            Text(buyLabel).font(Theme.font(15, .black))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Capsule().fill(Theme.coral)
            .shadow(color: Theme.coral.opacity(0.32), radius: 14, y: 5))
        .accessibilityAddTraits(.isButton)
    }

    private var buyLabel: String {
        switch pick.kind {
        case .kin(let s): return "Adopt \(s.name)"
        case .scene: return "Take this scene"
        }
    }

    /// The shortfall, said once on the whole screen. A bar that is mostly full reads
    /// as progress; five yellow "320 to go" pills read as five refusals, which is
    /// what this screen used to open with.
    private var shortfall: some View {
        VStack(alignment: .leading, spacing: 7) {
            CoinBar(have: coins, need: pick.price, tint: tint)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(gap) to go")
                    .font(Theme.font(13, .black)).foregroundStyle(Theme.coinDark)
                if let work {
                    Text(work)
                        .font(Theme.font(11.5, .heavy)).foregroundStyle(Theme.muted)
                        .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// Coins over price, as a bar. Never empty at zero — a hairline of colour says the
/// bar is a thing that fills rather than a thing that is broken.
private struct CoinBar: View {
    let have: Int
    let need: Int
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let f = need > 0 ? min(1, max(0, Double(have) / Double(need))) : 1
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.paperSunk)
                Capsule().fill(tint)
                    .frame(width: max(6, geo.size.width * f))
            }
        }
        .frame(height: 9)
    }
}

// MARK: - Grid card

/// One of the picks that isn't the hero. Half the screen wide, so the art gets 78pt
/// instead of 54 and a scene finally gets a landscape crop.
private struct PickCard: View {
    let pick: ShopPick
    let held: Bool
    let affordable: Bool

    private var tint: Color { Theme.tier(pick.tier) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            art
            VStack(alignment: .leading, spacing: 6) {
                Text(pick.name)
                    .font(Theme.font(14.5, .black)).foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.75)

                HStack(spacing: 6) {
                    // Solid badge: you can buy this right now. Outline: not yet.
                    //
                    // This replaced a mint tick, which collided with the ramp — tier 2
                    // *is* mint, so an Ember you could not afford wore a green price
                    // pill next to a green "you can afford it" tick. One mark now
                    // carries both facts, in the badge's own existing vocabulary.
                    //
                    // It is not the greyed-out wall the affordance panel refuses: the
                    // art, the name and the number stay at full strength, and the card
                    // is as tappable either way. Only the fill behind the price moves.
                    KinCostBadge(price: pick.price, tier: pick.tier, filled: affordable)
                    Text("\(pick.fullPrice)")
                        .font(Theme.font(10.5, .heavy)).foregroundStyle(Theme.dim)
                        .strikethrough()
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 11).padding(.top, 9).padding(.bottom, 11)
        }
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(held ? tint : Theme.cardEdge, lineWidth: held ? 3 : 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 9, y: 3)
        .accessibilityElement(children: .combine)
    }

    private var art: some View {
        ZStack(alignment: .topLeading) {
            switch pick.kind {
            case .kin(let species):
                LinearGradient(colors: [tint.opacity(0.38), tint.opacity(0.11)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 112)
                    .overlay(alignment: .bottom) {
                        KinArtView(speciesID: species.id, size: 126)
                            .padding(.bottom, 4)
                    }
            case .scene(let scene):
                Image(scene.asset)
                    .resizable().scaledToFill()
                    .frame(height: 112)
                    .clipped()
            }

            if held {
                HStack(spacing: 3) {
                    KinIcon(.lock, size: 8, color: Theme.ink)
                    Text("HELD").font(Theme.font(8.5, .black)).foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, 7).padding(.vertical, 4)
                .background(Capsule().fill(tint))
                .padding(8)
            }
        }
        .frame(height: 112)
        .frame(maxWidth: .infinity)
        .clipped()
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
            return ("\(slots) pick\(slots == 1 ? "" : "s"), all of what's left",
                    "Everything you don't own is already on this screen. There are no weights and no rare slot.")
        }
        return ("\(slots) picks, drawn evenly",
                "Every kin and scene you don't own has exactly the same chance of showing up. There are no weights and no rare slot.")
    }

    private var claims: [(String, String)] {
        [drawClaim,
         ("A pick is a discount, not a prize",
          "Everything on this screen is in the Collection too, at full price, always. A pick just takes \(state.pickDiscountPercent)% off."),
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
