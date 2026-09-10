import SwiftUI

/// The whole ladder, cheapest tier first — the price band *is* the progression, so
/// nothing needs a lock to imply order. Since 2026-09-06 the scenes are the second
/// shelf here, so the Shop can open on its picks alone (design/hicks-law-plan.md).
///
/// An unowned kin is drawn at full colour, named and priced. No padlocks, no `?`
/// tiles, no silhouettes, no desaturation: you can always see exactly what you are
/// saving for, which is the only thing making the coins worth earning.
struct CollectionView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    var onOpenShop: (() -> Void)?

    @State private var detail: ChibiSpecies?

    enum Shelf { case kin, scenes }
    @State private var shelf: Shelf = .kin

    private var tiers: [Int] {
        Array(Set(ChibiSpecies.catalog.map(\.tier))).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                shelfPicker
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)

                Text(shelf == .kin
                     ? "\(state.owned.count) of \(ChibiSpecies.catalog.count) owned · nothing here is ever locked or hidden"
                     : "\(state.ownedScenes.count) of \(Scene0.all.count) owned · the room behind your kin on the Kin tab")
                    .font(Theme.font(12, .heavy))
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)

                if shelf == .kin {
                    ForEach(tiers, id: \.self) { tier in
                        group(tier)
                    }

                    Text("That's the whole ladder. It never gets longer and nothing on it ever leaves.")
                        .font(Theme.font(11.5, .heavy))
                        .foregroundStyle(Theme.dim)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                } else {
                    sceneGrid
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(Theme.paper)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .top) { navRow }
        .hidesTabBar()
        .kinToast(state.toast)
        .sheet(item: $detail) { species in
            KinDetailSheet(species: species, onOpenShop: onOpenShop)
                .presentationDetents([.fraction(0.78)])
                .presentationDragIndicator(.visible)
        }
    }

    private var navRow: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.card)
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 2))
                    .padding(3)
                    .contentShape(Rectangle())
                    .padding(-3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()
            Text("Collection").font(Theme.font(17, .black)).foregroundStyle(Theme.ink)
            Spacer()
            WalletChip(coins: state.coins, compact: true)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .background(Theme.paper)
    }

    /// Two shelves, one selected. The same capsule pair Focus uses for its lengths.
    private var shelfPicker: some View {
        HStack(spacing: 8) {
            shelfChip("Kin", .kin)
            shelfChip("Scenes", .scenes)
        }
    }

    private func shelfChip(_ label: String, _ value: Shelf) -> some View {
        let on = shelf == value
        return Button { withAnimation(.easeInOut(duration: 0.16)) { shelf = value } } label: {
            Text(label)
                .font(Theme.font(14.5, .black))
                .foregroundStyle(on ? Theme.onDarkWarm : Theme.ink)
                .frame(minWidth: 84, minHeight: 36)
                .background(Capsule().fill(on ? Theme.ink : Theme.card)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2))
                .padding(.vertical, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
    }

    /// Home draws Sprout's tank now, so a scene only changes the Kin tab. The
    /// subtitle above says so before anyone spends 200 coins expecting Home to change.
    private var sceneGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            ForEach(Scene0.all) { scene in
                SceneCard(scene: scene,
                          owned: state.ownedScenes.contains(scene.id),
                          equipped: state.sceneID == scene.id,
                          price: state.currentPrice("scene:\(scene.id)"),
                          gap: max(0, state.currentPrice("scene:\(scene.id)") - state.coins),
                          onUse: { state.equipScene(scene.id) },
                          onBuy: { state.buyScene(scene) })
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder private func group(_ tier: Int) -> some View {
        let members = ChibiSpecies.catalog.filter { $0.tier == tier }
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TierPlate(tier: tier)
                Text(priceRange(members))
                    .font(Theme.font(10.5, .heavy))
                    .foregroundStyle(Theme.dim)
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }

            // One row per kin in every band. A band with two used to switch to a
            // pair of square tiles, which read as a different screen mid-scroll.
            VStack(spacing: 10) {
                ForEach(members) { species in
                    Button { detail = species } label: {
                        KinRow(species: species,
                               owned: state.ownedKin(species.id),
                               isActive: state.activeChibiID == species.id,
                               subtitle: subtitle(species))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func priceRange(_ members: [ChibiSpecies]) -> String {
        let prices = members.map(\.price).sorted()
        guard let low = prices.first, let high = prices.last else { return "" }
        if low == 0 { return "free" }
        return low == high ? "\(low)" : "\(low)–\(high)"
    }

    private func subtitle(_ species: ChibiSpecies) -> String? {
        guard let mine = state.ownedKin(species.id) else { return nil }
        return "Day \(state.daysTogether(mine)) together"
    }
}

/// The adoption card, filled in. Doubles as the place a kin is made active and
/// levelled up, because those are the two things you want while looking at it.
struct KinDetailSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    let species: ChibiSpecies
    var onOpenShop: (() -> Void)?

    private var mine: OwnedChibi? { state.ownedKin(species.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let mine {
                    AdoptionCard(species: species, kin: mine,
                                 daysTogether: state.daysTogether(mine),
                                 lifetime: state.game.stats(since: mine),
                                 canvasFinished: state.game.canvasFinished(since: mine),
                                 serial: serial)
                    ownedActions(mine)
                } else {
                    unownedBody
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 34)
        }
        .scrollIndicators(.hidden)
        .background(Theme.paper)
    }

    private var serial: Int {
        (state.owned.firstIndex { $0.speciesID == species.id } ?? 0) + 1
    }

    // MARK: Owned

    @ViewBuilder private func ownedActions(_ mine: OwnedChibi) -> some View {
        if let cost = mine.nextUpgradeCost {
            VStack(spacing: 10) {
                HStack {
                    Text("Next star").font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
                    Spacer()
                    StarPips(level: mine.level, size: 14)
                }
                Button {
                    if state.activeChibiID != species.id { state.setActive(species.id) }
                    state.upgradeActiveChibi()
                } label: {
                    HStack(spacing: 7) {
                        Text("Grow to \(mine.level + 1) stars").font(Theme.font(15, .black))
                        CoinDisc(size: 15)
                        Text("\(cost)").font(Theme.font(15, .black))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(state.coins >= cost ? Theme.coral : Theme.dim))
                }
                .buttonStyle(.plain)
                .disabled(state.coins < cost)

                if state.coins < cost {
                    let short = cost - state.coins
                    Text("\(short) \(short == 1 ? "coin" : "coins") to go. Nothing expires while you get there.")
                        .font(Theme.font(12, .bold)).foregroundStyle(Theme.muted)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.card))
        } else {
            Text("Three stars. That's the last one — \(mine.displayName) stays exactly like this from here.")
                .font(Theme.font(12.5, .bold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }

        if state.activeChibiID == species.id {
            Text("Out with you now")
                .font(Theme.font(13, .heavy))
                .foregroundStyle(Theme.mintDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Capsule().fill(Theme.mintSoft))
        } else {
            Button { state.setActive(species.id); dismiss() } label: {
                Text("Take \(mine.displayName) out")
                    .font(Theme.font(15, .black)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Capsule().fill(Theme.coral))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Not owned yet

    private var unownedBody: some View {
        VStack(spacing: 12) {
            TierPlate(tier: species.tier)
            KinArtView(speciesID: species.id, size: 180).frame(height: 176)
            Text(species.name).font(Theme.font(27, .black)).foregroundStyle(Theme.ink)
            Text("Starts at 1 star. You'll name it next.")
                .font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)

            let price = state.currentPrice("kin:\(species.id)")
            let short = price - state.coins

            if price < species.price {
                HStack(spacing: 8) {
                    Text("\(species.price)")
                        .font(Theme.font(13, .heavy)).foregroundStyle(Theme.dim).strikethrough()
                    Text("Today's pick · \(state.game.discountPercent)% off")
                        .font(Theme.font(12, .black)).foregroundStyle(Theme.ink)
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.tier(species.tier)))
                }
            }

            // The three numbers a student actually asks, in order. This used to be a
            // second sheet behind the Adopt button; now Adopt is the last tap.
            if short <= 0 {
                VStack(spacing: 0) {
                    priceRow("Collection price", value: "\(species.price)", struck: price < species.price)
                    if price < species.price {
                        priceRow("Today's pick · \(state.game.discountPercent)% off", value: "\(price)", emphasis: true)
                    }
                    Rectangle().fill(Theme.hairline).frame(height: 1).padding(.vertical, 4)
                    priceRow("Wallet after", value: "\(state.coins - price)", emphasis: true)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.card))
            }

            if short > 0 {
                AffordPanel(gap: short, balance: state.coins, price: price,
                            work: state.workToAfford("kin:\(species.id)"))
                Button { dismiss(); onOpenShop?() } label: {
                    Text("Open today's tasks")
                        .font(Theme.font(15, .black)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(Theme.coral))
                }
                .buttonStyle(.plain)
                Text("\(species.name) stays in the Collection at \(species.price) forever, and comes back into the picks. Nothing here expires.")
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.dim)
                    .multilineTextAlignment(.center)
            } else {
                Button { dismiss(); state.adoptNow(species) } label: {
                    HStack(spacing: 7) {
                        Text("Adopt \(species.name)").font(Theme.font(15, .black))
                        CoinDisc(size: 15)
                        Text("\(price)").font(Theme.font(15, .black))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Capsule().fill(Theme.coral)
                        .shadow(color: Theme.coral.opacity(0.35), radius: 16, y: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func priceRow(_ label: String, value: String, struck: Bool = false, emphasis: Bool = false) -> some View {
        HStack {
            Text(label).font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
            Spacer()
            HStack(spacing: 5) {
                CoinDisc(size: emphasis ? 14 : 12)
                Text(value)
                    .font(Theme.font(emphasis ? 16 : 13, .black))
                    .foregroundStyle(struck ? Theme.dim : Theme.ink)
                    .strikethrough(struck)
            }
        }
        .padding(.vertical, 5)
    }
}

/// The state that must never scold. The gap is a green success field with a bar and
/// the number restated as work, not a red warning and not a greyed-out wall.
struct AffordPanel: View {
    let gap: Int
    let balance: Int
    let price: Int
    let work: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(gap) \(gap == 1 ? "coin" : "coins") to go")
                    .font(Theme.font(16, .black)).foregroundStyle(Theme.mintDark)
                Spacer()
                Text("\(balance) of \(price)")
                    .font(Theme.font(12, .heavy)).foregroundStyle(Theme.mintDark.opacity(0.75))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.card)
                    Capsule().fill(Theme.mint)
                        .frame(width: max(6, geo.size.width * min(1, Double(balance) / Double(max(price, 1)))))
                }
            }
            .frame(height: 9)

            if let work {
                Text(work).font(Theme.font(12.5, .bold)).foregroundStyle(Theme.mintDark)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.mintSoft))
    }
}
