import SwiftUI

/// The shop, built on TFT's grammar of value and none of its grammar of loss.
///
/// Kept from TFT: a five-slot row, tier-coloured cost badges and plates, and the
/// lock. Refused: paying to reroll, a countdown to a refresh, exclusivity, and odds
/// you cannot check. A pick here is a 20% discount on something that is also in the
/// Collection at full price, forever — so rerolling can never cost you a thing you
/// wanted, which is why the reroll button carries no price at all.
struct KinShopView: View {
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

                Text("Struck price is the Collection price. Every pick is 20% off. Long-press a slot to hold it.")
                    .font(Theme.font(10.5, .heavy))
                    .foregroundStyle(Theme.dim)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20).padding(.top, 12)

                if let held = state.lockedPick, let pick = state.game.resolvePick(held) {
                    heldPanel(pick).padding(.top, 12)
                }

                rerollButton.padding(.top, 14)

                sectionHead("Kin", trailing: "\(state.owned.count) of \(ChibiSpecies.catalog.count)")
                    .padding(.top, 26)
                kinGrid.padding(.top, 10)

                sectionHead("Scenes", trailing: "\(state.ownedScenes.count) of \(Scene0.all.count)")
                    .padding(.top, 26)
                // Home draws Sprout's tank now, so a scene only changes the Kin tab.
                // Said here, before anyone spends 200 coins expecting Home to change.
                Text("The room behind your kin on the Kin tab.")
                    .font(Theme.font(11.5, .heavy))
                    .foregroundStyle(Theme.dim)
                    .padding(.horizontal, 20).padding(.top, 2)
                sceneGrid.padding(.top, 10)

                honestyEntry.padding(.top, 26)
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
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.card)
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

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
        switch state.rerollsLeft {
        case 0: return "Back tomorrow"
        case 1: return "Free · 1 left today"
        default: return "Free · \(state.rerollsLeft) left today"
        }
    }

    /// No cost badge on this control, ever. It is not disabled while it runs either —
    /// there is nothing to protect a double tap from.
    private var rerollButton: some View {
        Button { state.rerollPicks() } label: {
            HStack(spacing: 10) {
                KinIcon(.reroll, size: 20, color: state.rerolling ? Theme.dim : Theme.ink)
                    .rotationEffect(.degrees(state.rerolling ? 180 : 0))
                    .animation(.easeInOut(duration: 0.42), value: state.rerolling)
                Text(state.rerolling ? "Rerolling…"
                     : (state.lockedPick == nil ? "Reroll picks" : "Reroll the other four"))
                    .font(Theme.font(15, .black))
                    .foregroundStyle(state.rerollsLeft == 0 ? Theme.dim : Theme.ink)
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
        .padding(.horizontal, 20)
    }

    // MARK: Sections

    private var kinGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            ForEach(ChibiSpecies.catalog) { species in
                Button { detail = species } label: {
                    KinCard(species: species,
                            owned: state.ownedKin(species.id),
                            isActive: state.activeChibiID == species.id)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    private var sceneGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            ForEach(Scene0.all) { scene in
                SceneCard(scene: scene,
                          owned: state.ownedScenes.contains(scene.id),
                          equipped: state.sceneID == scene.id,
                          price: state.currentPrice("scene:\(scene.id)"),
                          canAfford: state.coins >= state.currentPrice("scene:\(scene.id)"),
                          onUse: { state.equipScene(scene.id) },
                          onBuy: { state.buyScene(scene) })
            }
        }
        .padding(.horizontal, 20)
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

/// One of the five. A held slot reads by promotion — wider, lifted, white, ringed —
/// never by dimming the others into a wall.
private struct PickSlot: View {
    let pick: ShopPick
    let locked: Bool
    let gap: Int

    var body: some View {
        VStack(spacing: 4) {
            Group {
                switch pick.kind {
                case .kin(let species):
                    KinArtView(speciesID: species.id, size: locked ? 58 : 52)
                        .frame(height: locked ? 52 : 47)
                case .scene(let scene):
                    Image(scene.asset)
                        .resizable().scaledToFill()
                        .frame(height: locked ? 52 : 47)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
            }

            Text("\(pick.fullPrice)")
                .font(Theme.font(9.5, .heavy))
                .foregroundStyle(Theme.dim)
                .strikethrough()

            KinCostBadge(price: pick.price, tier: pick.tier, compact: true)

            if gap > 0 {
                Text("\(gap) to go")
                    .font(Theme.font(9.5, .heavy))
                    .foregroundStyle(Theme.coinDark)
                    .padding(.horizontal, 5).padding(.vertical, 1.5)
                    .background(Capsule().fill(Theme.coinSoft))
            }
        }
        .padding(.horizontal, 3).padding(.top, 6).padding(.bottom, 5)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(locked ? Theme.card : Theme.unowned)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.tier(pick.tier), lineWidth: locked ? 2.5 : 2))
                .shadow(color: locked ? Theme.tier(pick.tier).opacity(0.28) : .clear, radius: 0, y: 0)
        )
        .overlay(alignment: .topTrailing) {
            Text("−20%")
                .font(Theme.font(8, .black))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 4).padding(.vertical, 1.5)
                .background(Capsule().fill(Theme.tier(pick.tier)))
                .offset(x: 5, y: -5)
        }
        .overlay(alignment: .top) {
            if locked {
                HStack(spacing: 3) {
                    KinIcon(.lock, size: 9, color: Theme.ink)
                    Text("HELD").font(Theme.font(8, .black)).foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, 5).padding(.vertical, 1.5)
                .background(Capsule().fill(Theme.tier(pick.tier)))
                .offset(y: -8)
            }
        }
        .scaleEffect(locked ? 1.06 : 1, anchor: .bottom)
        .opacity(locked ? 1 : 0.98)
        .zIndex(locked ? 1 : 0)
    }
}

// MARK: - Scene card

private struct SceneCard: View {
    let scene: Scene0
    let owned: Bool
    let equipped: Bool
    let price: Int
    let canAfford: Bool
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
                .disabled(!canAfford)
                .opacity(canAfford ? 1 : 0.5)
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
    private let claims: [(String, String)] = [
        ("Five slots, drawn evenly",
         "Every kin and scene you don't own has exactly the same chance of showing up. There are no weights and no rare slot."),
        ("A pick is a discount, not a prize",
         "Everything in the row is in the Collection too, at full price, always. A pick just takes 20% off."),
        ("Rerolling costs nothing, ever",
         "Three rerolls a day, no coins, no cooldown. You always end up with exactly the coins you started with."),
        ("Nothing ever leaves",
         "No timers, no seasons, no last chance. Anything you want today will still be here whenever you have the coins."),
    ]

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
