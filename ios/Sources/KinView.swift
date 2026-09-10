import SwiftUI

/// The Kin tab root — your kin, large, in its own scene.
///
/// Replaces the two-column shop grid that used to sit on this tab. The shop is still
/// here, but it is one push away, so the screen you land on is the one with the
/// character on it rather than the one with the prices on it.
///
/// Deviation from the handoff, and the same one Home v2 made: the artboards budget
/// 20pt of top chrome on a 390x844 canvas, and a real iPhone spends about 99. The
/// scene is sized from the headroom that is actually there and everything under it
/// scrolls, rather than being pinned to absolute y positions that would collide.
struct KinView: View {
    @EnvironmentObject var state: AppState

    @State private var bubble: String?
    @State private var bubbleTask: Task<Void, Never>?
    @State private var showCollection = false
    @State private var savingLook = false
    @State private var lookName = ""
    @State private var showingPlus = false
    @State private var showShop = false
    @State private var detail: ChibiSpecies?

    private var kin: OwnedChibi { state.activeChibi }
    private var scene: Scene0 { Scene0.find(state.sceneID) }
    private var isFirstRun: Bool { state.owned.count == 1 && state.coins == 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    stage
                    careRow.padding(.top, 16)
                    if isFirstRun {
                        Text("Free, unlimited, always. No cooldown.")
                            .font(Theme.font(11.5, .heavy))
                            .foregroundStyle(Theme.dim)
                            .padding(.top, 10)
                    }
                    wardrobeCard.padding(.top, 20)
                    savedLooksCard.padding(.top, 16)
                    if let season = state.currentSeason {
                        SeasonCard(season: season)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }
                    togetherStrip.padding(.top, 16)
                    collectionCard.padding(.top, 16)
                }
                .padding(.bottom, Theme.tabClearance)
            }
            .scrollIndicators(.hidden)
            .background(Theme.paper)
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showCollection) {
                CollectionView(onOpenShop: { showCollection = false; showShop = true })
            }
            .navigationDestination(isPresented: $showShop) { KinShopView() }
        }
        .sheet(item: $detail) { species in
            KinDetailSheet(species: species)
                .presentationDetents([.fraction(0.78)])
                .presentationDragIndicator(.visible)
        }
        .kinToast(state.toast, bottom: 104)
        .kinAdoptionFlow()
        .onChange(of: state.meetKinRequest) { _, new in
            guard new != nil else { return }
            showShop = false
            showCollection = false
        }
    }

    // MARK: - Stage

    private var stage: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { _ in Color.clear }
                .background(
                    // The tank plates are wide (4:3) and this stage is nearly
                    // square, so filling it would crop the scenery off both
                    // sides and leave only the empty centre. Fit to the width
                    // instead and let the floor carry on underneath — the
                    // plate's last rows are exactly `floor`, and the gradient
                    // continues the painting's own ramp from there so the art
                    // does not look like it stops on a flat block.
                    // The plate is 4:3 fitted to the width, so it ends three
                    // quarters of the way down its own width; the ramp starts
                    // there rather than at the top of the stage, or it would
                    // have drifted off the plate's last row by the time they
                    // meet and reintroduce the step.
                    GeometryReader { geo in
                        LinearGradient(
                            stops: [.init(color: scene.floor, location: 0),
                                    .init(color: scene.floor,
                                          location: min(1, geo.size.width * 0.75 / max(geo.size.height, 1))),
                                    .init(color: scene.floorDeep, location: 1)],
                            startPoint: .top, endPoint: .bottom)
                    }
                        .overlay(alignment: .top) {
                            Image(scene.asset)
                                .resizable()
                                .scaledToFit()
                        }
                )
                .overlay(
                    RadialGradient(colors: [.white.opacity(scene.isDark ? 0.0 : 0.30), .clear],
                                   center: UnitPoint(x: 0.5, y: 0.78),
                                   startRadius: 0, endRadius: 260)
                )
                .overlay(alignment: .bottom) {
                    // Keeps the cream section from cutting hard against dark art.
                    if scene.isDark {
                        LinearGradient(colors: [Theme.hex(0x141A28).opacity(0), Theme.hex(0x141A28).opacity(0.30)],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 120)
                    }
                }
                .frame(height: 430)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30,
                                                  style: .continuous))

            VStack(spacing: 8) {
                speechBubble
                namePlate
                KinArtView(speciesID: kin.speciesID,
                           level: kin.level,
                           skin: kin.skinID,
                           animation: state.animation,
                           size: isFirstRun ? 164 : 212)
                    .frame(height: isFirstRun ? 158 : 200)
                starPlate
            }
            .padding(.bottom, 16)
        }
        .frame(height: 430)
        // Same chip, same gutter, same y as Home. Kin used to carry a separate shop
        // door beside a plain wallet, which put two shop entrances on the tab and
        // sat 4pt off Home's gutter — enough that switching tabs made the corner
        // jump.
        .overlay(alignment: .topTrailing) {
            Button { showShop = true } label: {
                WalletChip(coins: state.coins, onDark: scene.isDark, showsShop: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Coins and shop")
            .padding(.trailing, 20)
            .padding(.top, 64)
        }
    }

    private var speechBubble: some View {
        Text(bubble ?? idleCopy)
            .font(Theme.font(13.5, .bold))
            .foregroundStyle(scene.isDark ? .white : Theme.ink)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(GlassPill(onDark: scene.isDark, strong: true))
            .animation(.easeInOut(duration: 0.16), value: bubble)
    }

    private var idleCopy: String {
        isFirstRun ? "This one is yours. It's free." : "\(kin.displayName) was fine without you. Mostly."
    }

    /// An unnamed kin gets a dashed invitation instead of a plate, because a plate
    /// reading "Moss" looks like a label rather than a name.
    @ViewBuilder private var namePlate: some View {
        if kin.isNamed {
            Text(kin.displayName)
                .font(Theme.font(14.5, .black))
                .foregroundStyle(scene.isDark ? .white : Theme.ink)
                .padding(.horizontal, 15).padding(.vertical, 6)
                .background(GlassPill(onDark: scene.isDark, strong: true))
        } else {
            Button { state.beginAdoption(kin.species); state.advanceAdoption(to: .naming) } label: {
                HStack(spacing: 7) {
                    KinIcon(.die, size: 15, color: Theme.muted)
                    Text("Name your kin")
                        .font(Theme.font(13.5, .black))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 15).padding(.vertical, 6)
                .background(Capsule().fill(Theme.card))
                .overlay(Capsule().strokeBorder(Theme.hex(0xE5DDD0),
                                                style: StrokeStyle(lineWidth: 2, dash: [4, 3])))
            }
            .buttonStyle(.plain)
        }
    }

    private var starPlate: some View {
        StarPips(level: kin.level, size: 15, spacing: 5)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(GlassPill(onDark: scene.isDark, strong: true))
    }

    // MARK: - Care

    private var careRow: some View {
        HStack(spacing: 0) {
            ForEach(AppState.CareKind.allCases, id: \.self) { kind in
                CareButton(glyph: kind.glyph, label: kind.label) { care(kind) }
                if kind != .snack { Spacer(minLength: 0) }
            }
        }
        .padding(.horizontal, 24)
    }

    private func care(_ kind: AppState.CareKind) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        state.care(kind)
        bubbleTask?.cancel()
        bubble = kind.bubble(kin.displayName)
        bubbleTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(3200))
            guard !Task.isCancelled else { return }
            bubble = nil
        }
    }

    // MARK: - Wardrobe

    /// The whole rack, on the tab the kin is on.
    ///
    /// It used to be a rail on the page inside Home's tank, which meant tapping a
    /// costume and tapping the water were the same gesture, and the shop lived on one
    /// tab while the wearing lived on another. Here it sits under the kin it dresses,
    /// and every swatch is that kin actually wearing the thing.
    @ViewBuilder private var wardrobeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Wardrobe")
                    .font(Theme.font(15, .black)).foregroundStyle(Theme.ink)
                Spacer()
                Text("\(ownedCostumes) of \(Costume.catalog.count)")
                    .font(Theme.font(12, .heavy)).foregroundStyle(Theme.muted)
            }

            if kin.level < 3 {
                // A costume has nowhere to sit on a one- or two-star kin — the rig has no
                // slot until stage III — so say that rather than show a rail that does nothing.
                Text("Costumes fit at three stars. \(kin.displayName) has \(kin.level).")
                    .font(Theme.font(12.5, .bold)).foregroundStyle(Theme.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    // Lazy on purpose. Every swatch is a 646px still, so a plain HStack
                    // decodes nineteen of them — about 32MB — the moment the tab opens,
                    // and the whole page hitches. Lazily, only what is on screen is built.
                    LazyHStack(spacing: 6) {
                        ForEach(Costume.catalog) { costume in
                            costumeSwatch(costume)
                        }
                        // Plus looks sit in the same rail, in full colour, with
                        // "Plus" where a coin price would be — exactly how a coin
                        // item is drawn (`PLUS-SPEC.md` section 4). Nothing is
                        // greyed and nothing carries a lock. An empty catalogue
                        // draws nothing at all: an empty Plus shelf reads as a thing
                        // taken away.
                        ForEach(PlusLooks.looks) { look in
                            plusLookSwatch(look)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, -16)
            }
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 12)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.card).shadow(color: .black.opacity(0.05), radius: 8, y: 2))
        .padding(.horizontal, 20)
    }

    private var ownedCostumes: Int {
        Costume.catalog.filter { state.game.ownedLooks.contains($0.id) }.count
    }

    /// What the kin has on. `classic` is not a costume: it means nobody has chosen, and
    /// the page puts the kin in its coat's default — so that is the swatch to tick.
    private var wornCostumeID: String {
        if Costume.ids.contains(kin.skinID) { return kin.skinID }
        return Costume.coatDefault[SproutView.coat(kin.speciesID)] ?? ""
    }

    private func costumeSwatch(_ costume: Costume) -> some View {
        let owned = state.game.ownedLooks.contains(costume.id)
        let worn = wornCostumeID == costume.id
        return Button {
            guard owned else { return }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            state.wear(costume)
        } label: {
            VStack(spacing: 4) {
                SproutImage(speciesID: kin.speciesID, level: 3, skin: costume.id, size: 46)
                    .frame(width: 54, height: 34)
                    .opacity(owned ? 1 : 0.35)
                    .overlay(alignment: .topTrailing) {
                        if !owned { KinIcon(.lock, size: 11, color: Theme.dim) }
                    }
                Text(owned ? costume.name : "\(costume.price)")
                    .font(Theme.font(10, .heavy))
                    .foregroundStyle(owned ? Theme.ink : Theme.dim)
                    .lineLimit(1)
            }
            .frame(width: 62)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(owned ? Theme.hex(0xF6F1E6) : Theme.unowned)
                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(worn ? Theme.mint : Theme.hairline, lineWidth: 2)))
        }
        .buttonStyle(.plain)
        .disabled(!owned)
        .accessibilityLabel(owned ? "\(costume.name)\(worn ? ", worn" : "")"
                                  : "\(costume.name), \(costume.price) coins, not bought")
    }

    /// A Plus coat, previewed on an **example** fish rather than the student's own.
    ///
    /// Showing a coat they do not have on the animal they love is the padlock
    /// feeling wearing a costume. The example fish is the whole reason this is a
    /// separate swatch and not a branch inside `costumeSwatch`.
    private func plusLookSwatch(_ look: PlusLooks.Look) -> some View {
        let owned = state.game.ownedLooks.contains(look.skinID)
        return Button {
            if owned || state.isPlus {
                state.wear(plusLook: look.skinID)
            } else {
                showingPlus = true
            }
        } label: {
            VStack(spacing: 3) {
                KinArtView(speciesID: PlusLooks.exampleSpeciesID, level: 3,
                           skin: look.skinID, size: 40)
                    .frame(width: 52, height: 44)
                Text(owned ? look.name : "Plus")
                    .font(Theme.fixedFont(9.5, .black))
                    .foregroundStyle(owned ? Theme.muted : Theme.coralShade)
                    .lineLimit(1)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(owned ? Theme.paperSunk : Theme.coralSoft))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(owned ? "\(look.name), yours"
                                  : "\(look.name), in Plus, shown on an example fish")
    }

    // MARK: - Saved looks

    /// Combinations of kin, costume and scene, kept so they can be put back on.
    ///
    /// Free saves three, Plus saves as many as you like. The thing that matters
    /// here is the sentence in `PLUS-SPEC.md` section 7: **every combination already
    /// saved stays applicable forever, including the ones above three.** A lapse
    /// stops new saves. It never deletes one and never greys one out, so this rail
    /// looks the same the day after a subscription ends as it did the day before.
    @ViewBuilder private var savedLooksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Saved looks")
                    .font(Theme.font(15, .black))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if state.canSaveLook {
                    Button { savingLook = true } label: {
                        Text("Save this one")
                            .font(Theme.font(12, .heavy))
                            .foregroundStyle(Theme.coralShade)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { showingPlus = true } label: {
                        Text("More saves · Plus")
                            .font(Theme.font(12, .heavy))
                            .foregroundStyle(Theme.muted)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
            }

            if state.savedLooks.isEmpty {
                Text("Save how your kin looks right now, and put it back on any time.")
                    .font(Theme.font(12, .heavy))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(state.savedLooks) { look in
                            Button { state.wearSavedLook(look.id) } label: {
                                VStack(spacing: 4) {
                                    KinArtView(speciesID: look.speciesID, level: 3,
                                               skin: look.costumeID, size: 40)
                                        .frame(width: 52, height: 44)
                                    Text(look.name)
                                        .font(Theme.fixedFont(9.5, .black))
                                        .foregroundStyle(Theme.muted)
                                        .lineLimit(1)
                                }
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Theme.paperSunk))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Remove", role: .destructive) {
                                    state.removeSavedLook(look.id)
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.card).shadow(color: .black.opacity(0.05), radius: 8, y: 2))
        .padding(.horizontal, 20)
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
    }

    // MARK: - Together since

    /// Real numbers, and every one of them only ever goes up. With nothing on it yet
    /// the strip says the day out loud instead of printing three zeros, because a row
    /// of zeros reads as failure on the one strip whose whole promise is that it climbs.
    /// Counted from the day this kin arrived, like its card.
    private var mine: LifetimeStats { state.game.stats(since: kin) }

    @ViewBuilder private var togetherStrip: some View {
        if mine == LifetimeStats() {
            VStack(spacing: 4) {
                Text("Day \(state.daysTogether(kin)) together")
                    .font(Theme.font(15, .black))
                    .foregroundStyle(Theme.ink)
                Text("Finished assignments, focus time and lessons start showing up here.")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.card).shadow(color: .black.opacity(0.05), radius: 8, y: 2))
            .padding(.horizontal, 20)
        } else {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { i, cell in
                        VStack(spacing: 2) {
                            Text(cell.value).font(Theme.font(16, .black)).foregroundStyle(Theme.ink)
                            Text(cell.label).font(Theme.font(10.5, .heavy)).foregroundStyle(Theme.muted)
                        }
                        .frame(maxWidth: .infinity)
                        if i < cells.count - 1 {
                            Rectangle().fill(Theme.hairline).frame(width: 1, height: 30)
                        }
                    }
                }
                .padding(.vertical, 8).padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.card).shadow(color: .black.opacity(0.05), radius: 8, y: 2))

                Text("Every one of these only ever goes up.")
                    .font(Theme.font(10.5, .heavy))
                    .foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 20)
        }
    }

    /// The Canvas cell is dropped rather than zeroed when Canvas was never connected —
    /// a hard 0 there is a number the student has no way to earn.
    private var cells: [(value: String, label: String)] {
        let days = state.daysTogether(kin)
        var out: [(String, String)] = [("\(days)", days == 1 ? "day together" : "days together")]
        if let canvas = state.game.canvasFinished(since: kin), canvas > 0 {
            out.append(("\(canvas)", canvas == 1 ? "assignment" : "assignments"))
        }
        let h = mine.focusMinutes / 60, m = mine.focusMinutes % 60
        out.append((h > 0 ? "\(h)h \(m)m" : "\(m)m", "focused"))
        if out.count < 3 {
            out.append(("\(mine.lessonsRead)", mine.lessonsRead == 1 ? "lesson" : "lessons"))
        }
        return out
    }

    // MARK: - Collection card

    private var collectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { showCollection = true } label: {
                HStack(spacing: 8) {
                    KinIcon(.dock, size: 18, color: Theme.ink)
                    Text(isFirstRun
                         ? "\(ChibiSpecies.catalog.count - state.owned.count) more to meet"
                         : "Collection")
                        .font(Theme.font(15, .black)).foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(state.owned.count) of \(ChibiSpecies.catalog.count)")
                        .font(Theme.font(12, .heavy)).foregroundStyle(Theme.muted)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .black)).foregroundStyle(Theme.dim)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Fixed-width tiles in a rail that scrolls. With six species the row
            // filled the card; at nine a plain HStack grew past the screen and
            // dragged the whole tab's layout out with it.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ChibiSpecies.catalog) { species in
                        let mine = state.ownedKin(species.id)
                        Button { detail = species } label: {
                            KinArtView(speciesID: species.id, level: mine?.level ?? 1,
                                       skin: mine?.skinID ?? "classic", size: 42)
                                .frame(width: 50, height: 38)
                                .padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(mine == nil ? Theme.unowned : Theme.hex(0xF6F1E6))
                                    .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .strokeBorder(borderColor(species), lineWidth: 2)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(mine.map { "\(species.name), \($0.level) of 3 stars" }
                                            ?? "\(species.name), not met yet")
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)

            if isFirstRun {
                Text("Finishing things earns coins. Nothing here ever expires.")
                    .font(Theme.font(11.5, .heavy)).foregroundStyle(Theme.dim)
            }
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 12)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.card).shadow(color: .black.opacity(0.05), radius: 8, y: 2))
        .padding(.horizontal, 20)
    }

    private func borderColor(_ species: ChibiSpecies) -> Color {
        if state.activeChibiID == species.id { return Theme.mint }
        if species.tier == 5 { return Theme.tier(5) }
        return Theme.hairline
    }
}
