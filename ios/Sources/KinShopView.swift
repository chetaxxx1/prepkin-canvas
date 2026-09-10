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
                                     work: state.workToAfford(hero.id),
                                     homeScene: homeScene,
                                     homeSpecies: homeSpecies,
                                     homeLevel: homeLevel)
                            .padding(.horizontal, 20).padding(.top, 14)
                            .onTapGesture { open(hero) }
                            .onLongPressGesture { hold(hero) }
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(restOfPicks) { pick in
                            PickCard(pick: pick,
                                     held: state.isHeld(pick.id),
                                     affordable: pick.price <= state.coins,
                                     homeScene: homeScene,
                                     homeSpecies: homeSpecies,
                                     homeLevel: homeLevel)
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
    ///
    /// "off its **Collection** price" is not decoration. A bare "20% off" is a
    /// discount against nothing; naming the Collection is what makes the number
    /// checkable, and it points at the screen where you can go and check it.
    /// `test/ios-flows.sh` asserts the word is here.
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
                Text("Everything here is \(state.pickDiscountPercent)% off its Collection price. Press and hold one to keep it.")
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

    /// The student's own Home, which is the set every card is photographed on.
    private var homeScene: Scene0 { Scene0.find(state.sceneID) }
    private var homeSpecies: String { state.activeChibiID ?? ChibiSpecies.catalog[0].id }
    private var homeLevel: Int { state.ownedKin(homeSpecies)?.level ?? 1 }

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
            Text("Every kin and every scene is yours. There is nothing left for the shop to put on sale, so spend what you earn on stars instead.")
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

// MARK: - Tank tile

/// The art on every card in the shop: a painted tank, bled to all four edges, with a
/// kin standing on its floor.
///
/// This is the whole second pass. The first rebuild made the cards big but left the kin
/// on a flat wash of its tier colour, which on Prepkin's pale ramp is a small blob on
/// near-white — the thing George called ugly, correctly. Every shop worth copying
/// (Finch, Forest, Alan, the Reddit avatar store) puts the item **in a place** and lets
/// the art reach the edges. Prepkin already owns five painted places, so no new art was
/// needed; the scenes were simply never used anywhere but Home.
///
/// What each card shows is a picture of the student's own Home with one thing changed:
/// a kin card puts that kin in the tank they already have, a scene card puts the kin
/// they already have in that tank. One variable per card, and every card is an honest
/// product shot rather than a swatch.
private struct TankTile: View {
    let scene: Scene0
    let speciesID: String
    /// Stage of the kin standing in it. Unowned picks are stage I; the student's own
    /// kin, which is who stands in a *scene* card, can be any of the three.
    var level: Int = 1
    let height: CGFloat
    /// How tall the drawn kin should be as a fraction of the tile. Real ink, not frame.
    var kinHeight: CGFloat = 0.60
    /// -1…1. Slides the crop across the painting so four cards on one tank are four
    /// framings of it rather than four copies. Honest — it is the same water.
    var pan: CGFloat = 0

    /// **`KinArtView(size:)` is not the drawn height of the kin.**
    ///
    /// The stills are square frames the rig drew into, and the kin sits flush to the
    /// bottom of one filling only part of it — measured off the catalogue, 0.42 of the
    /// frame at stage I, 0.50 at II, 0.62 at III. Asking for `size: 176` to fill a
    /// 176pt band is what left the first pass floating in a third of its card. Divide
    /// by this and the drawn kin is the size you asked for, at any stage.
    private static func inkRatio(_ level: Int) -> CGFloat {
        switch level {
        case 3: return 0.62
        case 2: return 0.50
        default: return 0.42
        }
    }

    /// The tanks are all 1440 × 1080.
    private static let art: CGFloat = 4.0 / 3.0

    var body: some View {
        GeometryReader { geo in
            // Sized by hand rather than left to `scaledToFill`, for two reasons.
            //
            // Bottom-anchored: the floor is the bottom third of every painting, and a
            // centred crop of a 4:3 tank in a wide card shows the middle of the water
            // and none of the ground to stand on. A `ZStack(alignment: .bottom)` over an
            // oversized image does that; `scaledToFill` centres and cannot be told not to.
            //
            // And wide enough to pan: a 4:3 painting covering a card this shape has only
            // a few points of horizontal slack, so the first cut slid it clean off its
            // own card and printed a white strip down the left. The width is stretched
            // 14% past cover so there is always room, and the offset is clamped to the
            // slack that actually exists.
            let w = max(geo.size.width, 1)
            let drawnW = max(w * 1.14, height * Self.art)
            let drawnH = drawnW / Self.art
            let slack = (drawnW - w) / 2

            ZStack(alignment: .bottom) {
                Image(scene.asset)
                    .resizable()
                    .frame(width: drawnW, height: max(drawnH, height))
                    .offset(x: min(max(pan * slack, -slack), slack))

                // The transparent top of the still overhangs the sky and costs nothing;
                // the tile clips it. Feet land just above the card's bottom edge.
                KinArtView(speciesID: speciesID, level: level,
                           size: height * kinHeight / Self.inkRatio(level))
                    .padding(.bottom, height * 0.05)
            }
            // `.bottom`, not the default centre. The stack is taller than the tile —
            // the stretched painting is, and so is the kin's own frame — and a centred
            // crop takes half that overflow off the bottom, which is the half with the
            // floor and the kin's feet in it. Centring here cut the hero off at the chin.
            .frame(width: w, height: height, alignment: .bottom)
            .clipped()
        }
        .frame(height: height)
    }
}

/// A small pill over the top-left of a tile. The one thing the art cannot say on its
/// own is which of the two things on this screen you are looking at — a scene card and
/// a kin card are both a kin in a tank, and only the tag separates them.
private struct TileTag: View {
    let text: String
    var tint: Color?
    var lock = false

    var body: some View {
        HStack(spacing: 4) {
            if lock { KinIcon(.lock, size: 9, color: Theme.ink) }
            Text(text).font(Theme.font(9.5, .black)).foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(tint ?? Theme.card.opacity(0.92)))
    }
}

/// A stable number in -1…1 from a pick's id, for `TankTile.pan`.
///
/// `hashValue` is seeded per process, so it would repan every card on every launch.
private func stablePan(_ id: String) -> CGFloat {
    let sum = id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
    return CGFloat(sum % 5 - 2) / 2
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
    /// The student's own tank and their own kin. A kin pick stands in that tank; a
    /// scene pick is that kin standing in the new one. Either way the card is a
    /// picture of their Home with one thing changed.
    let homeScene: Scene0
    let homeSpecies: String
    let homeLevel: Int

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
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(axLabel)
        .accessibilityHint(axHint)
    }

    /// Combining the children read out "RARE KIN, Droplet, 320, 400" — four numbers
    /// and no verb. Spelled out instead, because the press-and-hold is invisible to
    /// VoiceOver otherwise and it is the only way to keep a price.
    private var axLabel: String {
        let kind: String
        switch pick.kind {
        case .kin: kind = "\(Theme.tierName(pick.tier).lowercased()) kin"
        case .scene: kind = "scene"
        }
        let money = "\(pick.price) coins, down from \(pick.fullPrice)"
        // The same "You can afford it." the grid cards use, so one rule tells a
        // reader — and `test/ios-flows.sh` — whether any card on the screen is
        // within reach, hero or not.
        let can = gap > 0 ? "" : " You can afford it."
        return held ? "\(pick.name), \(kind). \(money). Held at this price.\(can)"
                    : "\(pick.name), \(kind). \(money).\(can)"
    }

    private var axHint: String {
        let holdPart = held ? "Press and hold to release it."
                            : "Press and hold to keep this price."
        if gap > 0 { return "\(gap) coins to go. Opens the details. \(holdPart)" }
        switch pick.kind {
        case .kin(let s): return "Adopts \(s.name). \(holdPart)"
        case .scene: return "Buys this scene. \(holdPart)"
        }
    }

    // MARK: Art

    /// Whichever of the two things is being sold, the picture is the same picture:
    /// a kin standing in a tank. A kin pick swaps the kin, a scene pick swaps the
    /// water, and `TileTag` is what says which.
    private var art: some View {
        ZStack(alignment: .topLeading) {
            switch pick.kind {
            case .kin(let species):
                TankTile(scene: homeScene, speciesID: species.id,
                         height: 196, kinHeight: 0.62)
            case .scene(let scene):
                TankTile(scene: scene, speciesID: homeSpecies, level: homeLevel,
                         height: 196, kinHeight: 0.56)
            }

            TileTag(text: held ? "HELD AT THIS PRICE" : kindLabel,
                    tint: held ? tint : nil, lock: held)
                .padding(12)
        }
        .frame(height: 196)
        .frame(maxWidth: .infinity)
        .clipped()
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
    let homeScene: Scene0
    let homeSpecies: String
    let homeLevel: Int

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
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(axLabel)
        .accessibilityHint(held ? "Press and hold to release this price."
                                : "Press and hold to keep this price.")
    }

    /// The solid-versus-outline badge is the only thing on the card that says whether
    /// you can buy it, and a fill is not a thing VoiceOver reads. It says so here.
    private var axLabel: String {
        let money = "\(pick.price) coins, down from \(pick.fullPrice)"
        let can = affordable ? "You can afford it." : ""
        return [held ? "\(pick.name), held." : "\(pick.name).", "\(money).", can]
            .filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// Four kin cards drawing the same equipped tank would read as four copies of one
    /// picture, so each one slides the crop across the painting by a stable amount.
    /// Same water, four framings — the way a lookbook shoots a set.
    private var art: some View {
        ZStack(alignment: .topLeading) {
            switch pick.kind {
            case .kin(let species):
                TankTile(scene: homeScene, speciesID: species.id,
                         height: 142, kinHeight: 0.60, pan: stablePan(pick.id))
            case .scene(let scene):
                TankTile(scene: scene, speciesID: homeSpecies, level: homeLevel,
                         height: 142, kinHeight: 0.54)
            }

            TileTag(text: held ? "HELD" : kindLabel,
                    tint: held ? tint : nil, lock: held)
                .padding(9)
        }
        .frame(height: 142)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var kindLabel: String {
        switch pick.kind {
        case .kin: return "KIN"
        case .scene: return "SCENE"
        }
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
