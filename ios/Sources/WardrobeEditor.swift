import SwiftUI

/// The Wardrobe door: dressing the kin as a live preview, not a list.
///
/// Instagram's avatar editor, mechanic for mechanic: the preview on the top half,
/// a sheet under it with a tab strip, a 3-column grid with the price under each
/// tile, one Done. Finch's closet gives it the **None** tile first. Ours puts the
/// student's own tank on top — the web page that draws Home's tank, in its own
/// see-through instance, which already takes `?costume=` and `?tank=` — so every
/// tap is the fish actually changing rather than a swatch lighting up.
///
/// Three things the grid never does: dim an unowned tile, draw a lock on it, or
/// hide it. An unowned costume is the student's own kin wearing it at full colour
/// with the coin price, and tapping it tries it on in the tank before it is bought.
struct WardrobeEditor: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Tab: String, CaseIterable, Identifiable {
        case costume = "Costume", coat = "Coat", scene = "Scene"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .costume
    /// An unowned costume being tried on. Preview only: nothing is written until it
    /// is bought, and closing the editor drops it.
    @State private var tryingOn: Costume?
    @State private var stageReady = false
    @State private var savingLook = false
    @State private var lookName = ""
    @State private var showingPlus = false
    @State private var detail: ChibiSpecies?

    /// The Costume grid, in order: None, then the rack cheapest first.
    static let costumeTiles: [Costume] = [Costume.none] + Costume.catalog

    private var kin: OwnedChibi { state.activeChibi }
    private var scene: Scene0 { Scene0.find(state.sceneID) }
    /// What the tank shows: the try-on if there is one, else what the kin has on.
    private var previewSkin: String { tryingOn?.id ?? kin.skinID }

    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    // Same tank geometry as Home, so the fish is the same size here as at home.
    private var screenWidth: CGFloat { UIScreen.main.bounds.width }
    private var screenHeight: CGFloat { UIScreen.main.bounds.height }
    private var sceneHeight: CGFloat { min(screenWidth * 0.836, screenHeight * 0.385) }
    private let mascotSize: CGFloat = 184
    private static let restLift: CGFloat = 0.07

    var body: some View {
        VStack(spacing: 0) {
            preview
            sheet
        }
        .background(scene.floor.ignoresSafeArea())
        .kinToast(state.toast, bottom: 24)
        .alert("Name this look", isPresented: $savingLook) {
            TextField("Look", text: $lookName)
                .autocorrectionDisabled()
            Button("Save") {
                let clean = lookName.trimmingCharacters(in: .whitespacesAndNewlines)
                state.saveLook(named: clean.isEmpty ? "Look" : clean)
                lookName = ""
            }
            Button("Cancel", role: .cancel) { lookName = "" }
        }
        .sheet(isPresented: $showingPlus) { PlusSheet(reason: .look) }
        .sheet(item: $detail) { species in
            KinDetailSheet(species: species)
                .presentationDetents([.fraction(0.78)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Preview

    /// The live tank, covered by the same still until the page has drawn — a look
    /// change is a reload, and the still of the new costume lands on the tap.
    private var preview: some View {
        ZStack(alignment: .top) {
            SproutView(speciesID: kin.speciesID,
                       level: kin.level,
                       skin: previewSkin,
                       animation: state.animation,
                       radius: mascotSize * SproutView.radiusRatio,
                       tank: scene.id,
                       placeholder: UIColor(scene.floor),
                       transparent: true,
                       reduceMotion: reduceMotion,
                       onReady: { ready in
                           withAnimation(.easeOut(duration: 0.25)) { stageReady = ready }
                       })
                .frame(width: screenWidth, height: sceneHeight)
                .accessibilityElement()
                .accessibilityLabel("\(kin.displayName) in the \(scene.name) tank")

            if !stageReady {
                Image(scene.asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: sceneHeight, alignment: .bottom)
                    .clipped()
                    .background(scene.floor)
                    .overlay(alignment: .bottom) {
                        SproutImage(speciesID: kin.speciesID, level: kin.level,
                                    skin: previewSkin, size: mascotSize)
                            .padding(.bottom, sceneHeight * Self.restLift)
                    }
                    .frame(width: screenWidth, height: sceneHeight)
                    .transition(.opacity)
            }

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(scene.isDark ? .white : Theme.ink)
                        .frame(width: 44, height: 44)
                        .background(GlassPill(onDark: scene.isDark, strong: false))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")

                Spacer()

                // The balance, because a price under a tile is a question about it.
                WalletChip(coins: state.coins, compact: true, onDark: scene.isDark)
                    .accessibilityLabel("\(state.coins) coins")

                Button { dismiss() } label: {
                    Text("Done")
                        .font(Theme.fixedFont(15, .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(Capsule().fill(Theme.coral))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Done")
                .padding(.leading, 8)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 60)
        }
        .frame(width: screenWidth, height: sceneHeight)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Sheet

    private var sheet: some View {
        VStack(spacing: 0) {
            tabStrip
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if tab == .costume && kin.level < 3 {
                        Text("Costumes fit at three stars. \(kin.displayName) has \(kin.level).")
                            .font(Theme.font(12, .heavy))
                            .foregroundStyle(Theme.muted)
                            .padding(.horizontal, 4)
                    }
                    LazyVGrid(columns: columns, spacing: 10) {
                        switch tab {
                        case .costume:
                            ForEach(Self.costumeTiles) { costume in costumeTile(costume) }
                            ForEach(PlusLooks.looks) { look in plusLookTile(look) }
                        case .coat:
                            ForEach(ChibiSpecies.catalog) { species in coatTile(species) }
                        case .scene:
                            ForEach(Scene0.all) { scene in sceneTile(scene) }
                        }
                    }
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 14)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.sheet,
                                   topTrailingRadius: Theme.Radius.sheet, style: .continuous)
                .fill(Theme.paper)
                .ignoresSafeArea(edges: .bottom)
        )
        // The sheet's top corners overlap the tank floor by their own radius, the way
        // a presented sheet sits over the screen under it.
        .padding(.top, -Theme.Radius.sheet)
    }

    /// Costume · Coat · Scene. The same capsule pair Focus uses for its lengths.
    private var tabStrip: some View {
        HStack(spacing: 8) {
            ForEach(Tab.allCases) { t in
                let on = tab == t
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { tab = t }
                } label: {
                    Text(t.rawValue)
                        .font(Theme.font(14.5, .black))
                        .foregroundStyle(on ? Theme.onDarkWarm : Theme.ink)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Capsule().fill(on ? Theme.ink : Theme.card)
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2))
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
            }
        }
    }

    // MARK: Tiles

    /// A tile is the student's own kin wearing the thing, its name, and either
    /// nothing (owned) or the coin price. The worn one has a mint ring; the one being
    /// tried on has an ink ring.
    private func costumeTile(_ costume: Costume) -> some View {
        let isNone = costume.id == Costume.none.id
        let owned = isNone || state.game.ownedLooks.contains(costume.id)
        let worn = wornCostumeID == costume.id
        let trying = tryingOn?.id == costume.id
        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if owned {
                tryingOn = nil
                state.wear(costume)
            } else {
                tryingOn = trying ? nil : costume
            }
        } label: {
            VStack(spacing: 5) {
                Group {
                    if isNone {
                        Text("None")
                            .font(Theme.font(13, .black))
                            .foregroundStyle(Theme.muted)
                    } else {
                        SproutImage(speciesID: kin.speciesID, level: 3, skin: costume.id, size: 92)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 78)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(worn ? Theme.mint : (trying ? Theme.ink : Theme.cardEdge),
                                  lineWidth: worn || trying ? 2 : 1))

                Text(costume.name)
                    .font(Theme.font(12, .heavy))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                if owned {
                    Color.clear.frame(height: 16)
                } else {
                    KinCostBadge(price: costume.price, tier: tier(for: costume.price),
                                 filled: false, compact: true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isNone ? "None" + (worn ? ", worn" : "")
                            : owned ? "\(costume.name)\(worn ? ", worn" : "")"
                            : "\(costume.name), \(costume.price) coins\(trying ? ", trying on" : "")")
    }

    /// A Plus coat, previewed on an example fish rather than the student's own —
    /// showing a coat they do not have on the animal they love is the padlock
    /// feeling wearing a costume (`PLUS-SPEC.md` section 4).
    private func plusLookTile(_ look: PlusLooks.Look) -> some View {
        let owned = state.game.ownedLooks.contains(look.skinID)
        return Button {
            if owned || state.isPlus { state.wear(plusLook: look.skinID) } else { showingPlus = true }
        } label: {
            VStack(spacing: 5) {
                KinArtView(speciesID: PlusLooks.exampleSpeciesID, level: 3, skin: look.skinID, size: 84)
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .fill(owned ? Theme.card : Theme.coralSoft))
                Text(look.name).font(Theme.font(12, .heavy)).foregroundStyle(Theme.ink).lineLimit(1)
                Text(owned ? " " : "Plus")
                    .font(Theme.fixedFont(10, .black))
                    .foregroundStyle(Theme.coralShade)
                    .frame(height: 16)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(owned ? "\(look.name), yours" : "\(look.name), in Plus, shown on an example fish")
    }

    /// One tile per kin in the catalogue. Owned: tap to take it out. Unowned: full
    /// colour with its price, and the tap opens the same kin sheet the Collection uses.
    private func coatTile(_ species: ChibiSpecies) -> some View {
        let mine = state.ownedKin(species.id)
        let active = state.activeChibiID == species.id
        return Button {
            if mine != nil {
                if !active { state.setActive(species.id) }
            } else {
                detail = species
            }
        } label: {
            VStack(spacing: 5) {
                KinArtView(speciesID: species.id, level: mine?.level ?? 1,
                           skin: mine?.skinID ?? "classic", size: 84)
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .fill(mine == nil ? Theme.unowned : Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .strokeBorder(active ? Theme.mint : Theme.tier(species.tier),
                                      lineWidth: active ? 2 : 1.5))
                Text(mine?.displayName ?? species.name)
                    .font(Theme.font(12, .heavy)).foregroundStyle(Theme.ink).lineLimit(1)
                if let mine {
                    StarPips(level: mine.level, size: 10, spacing: 3).frame(height: 16)
                } else {
                    KinCostBadge(price: species.price, tier: species.tier, filled: false, compact: true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mine.map { "\($0.displayName), \($0.level) of 3 stars\(active ? ", out now" : "")" }
                            ?? "\(species.name), \(species.price) coins")
    }

    /// One tile per tank: the plate itself, cropped to the tile. Owned: tap to move
    /// in. Unowned: full colour with its price; the tap buys it, or says the gap once.
    private func sceneTile(_ scene: Scene0) -> some View {
        let owned = state.ownedScenes.contains(scene.id)
        let equipped = state.sceneID == scene.id
        let price = state.currentPrice("scene:\(scene.id)")
        return Button {
            if owned {
                if !equipped { state.equipScene(scene.id) }
            } else {
                state.buyScene(scene)
            }
        } label: {
            VStack(spacing: 5) {
                Image(scene.asset)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .strokeBorder(equipped ? Theme.mint : Theme.cardEdge, lineWidth: equipped ? 2 : 1))
                Text(scene.name).font(Theme.font(12, .heavy)).foregroundStyle(Theme.ink).lineLimit(1)
                if owned {
                    Color.clear.frame(height: 16)
                } else {
                    KinCostBadge(price: price, tier: tier(for: price), filled: false, compact: true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(owned ? "\(scene.name)\(equipped ? ", your tank" : "")"
                            : "\(scene.name), \(price) coins")
    }

    // MARK: Footer

    /// Under the grid: the try-on's price while one is on, otherwise the saved looks.
    @ViewBuilder private var footer: some View {
        VStack(spacing: 10) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
            if let costume = tryingOn {
                tryOnRow(costume)
            } else {
                savedLooksRow
            }
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.bottom, 12)
        .background(Theme.paper)
    }

    /// The one primary action in the editor. Short of coins it is the same mint
    /// panel the Collection uses: the gap, the bar, the work it would take. Never
    /// greyed, never red, never a lock.
    @ViewBuilder private func tryOnRow(_ costume: Costume) -> some View {
        if state.coins >= costume.price {
            HStack(spacing: 10) {
                Button {
                    state.buyCostume(costume)
                    tryingOn = nil
                } label: {
                    HStack(spacing: 7) {
                        Text("Wear it").font(Theme.font(15, .black))
                        Text("·").font(Theme.font(15, .black)).opacity(0.6)
                        CoinDisc(size: 15)
                        Text("\(costume.price)").font(Theme.font(15, .black))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(minHeight: 50)
                    .background(Capsule().fill(Theme.coral)
                        .shadow(color: Theme.coral.opacity(0.35), radius: 16, y: 6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Wear the \(costume.name) for \(costume.price) coins")

                Button { tryingOn = nil } label: {
                    Text("Not now")
                        .font(Theme.font(14, .heavy)).foregroundStyle(Theme.muted)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } else {
            VStack(spacing: 8) {
                AffordPanel(gap: costume.price - state.coins, balance: state.coins,
                            price: costume.price, work: state.workToAfford(price: costume.price))
                Button { tryingOn = nil } label: {
                    Text("Not now")
                        .font(Theme.font(14, .heavy)).foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Combinations of kin, costume and scene, kept so they can be put back on. Free
    /// saves three; anything already saved stays wearable forever, paid or not.
    private var savedLooksRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Saved looks")
                    .font(Theme.font(13, .black)).foregroundStyle(Theme.ink)
                Spacer()
                if state.canSaveLook {
                    Button { savingLook = true } label: {
                        Text("Save look")
                            .font(Theme.font(13, .black)).foregroundStyle(Theme.coralShade)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { showingPlus = true } label: {
                        Text("More saves · Plus")
                            .font(Theme.font(13, .heavy)).foregroundStyle(Theme.muted).underline()
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            if state.savedLooks.isEmpty {
                Text("Save this look to put it back on later.")
                    .font(Theme.font(12, .heavy)).foregroundStyle(Theme.muted)
                    .padding(.bottom, 6)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(state.savedLooks) { look in
                            Button { state.wearSavedLook(look.id) } label: {
                                HStack(spacing: 6) {
                                    KinArtView(speciesID: look.speciesID, level: 3,
                                               skin: look.costumeID, size: 34)
                                        .frame(width: 36, height: 30)
                                    Text(look.name)
                                        .font(Theme.font(12, .heavy)).foregroundStyle(Theme.ink)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 7)
                                .frame(minHeight: 44)
                                .background(Capsule().fill(Theme.paperSunk))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Put on \(look.name)")
                            .contextMenu {
                                Button("Remove", role: .destructive) { state.removeSavedLook(look.id) }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: - Helpers

    /// What the kin has on. `classic` is not a costume: it means nobody has chosen,
    /// and the page puts the kin in its coat's default — so None is the tile to ring.
    private var wornCostumeID: String {
        Costume.ids.contains(kin.skinID) ? kin.skinID : Costume.none.id
    }

    /// Costumes and tanks borrow the kin tier ramp by price, as the shop's picks do.
    private func tier(for price: Int) -> Int {
        switch price {
        case 0..<200: return 1
        case 200..<400: return 2
        case 400..<700: return 3
        case 700..<1100: return 4
        default: return 5
        }
    }
}
