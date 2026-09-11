import SwiftUI

/// The Kin tab root — the kin's own page, the way Finch's home is the bird's house.
///
/// Since 2026-09-11 the tab is the tank and four doors, not a tank and a stack of
/// cards. The stage holds everything about the kin — the bubble, its name and stars,
/// the friendship word, the kin in whatever it is wearing — and the care buttons sit
/// on the water's bottom edge the way Abode keeps feed / clean / play inside the pet's
/// room. Under the tank: Wardrobe, Decorate, Collection, Card (Finch's Bag as a row
/// of doors, always all of them, never a "?"), then the Season as one dated row.
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
    @State private var showShop = false
    @State private var showWardrobe = false
    @State private var showDecorate = false
    @State private var showCard = false
    @State private var showSeason = false
    @State private var renaming = false
    @State private var draftName = ""

    private var kin: OwnedChibi { state.activeChibi }
    private var scene: Scene0 { Scene0.find(state.sceneID) }
    private var isFirstRun: Bool { state.owned.count == 1 && state.coins == 0 }

    /// How far the care circles reach up into the water. Half of a 60pt circle.
    private static let careOverlap: CGFloat = 30

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    stage
                    // Straddles the water's bottom edge: the circles sit half in the
                    // tank and half on the paper, the labels on the paper.
                    careRow.padding(.top, -Self.careOverlap)
                    if isFirstRun {
                        Text("Free, unlimited, always. No cooldown.")
                            .font(Theme.font(11.5, .heavy))
                            .foregroundStyle(Theme.dim)
                            .padding(.top, 10)
                    }
                    doors.padding(.top, 18)
                    if let season = state.currentSeason {
                        seasonRow(season).padding(.top, 12)
                    }
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
        .fullScreenCover(isPresented: $showWardrobe) {
            WardrobeEditor().environmentObject(state)
        }
        .fullScreenCover(isPresented: $showDecorate) {
            DecorateEditor().environmentObject(state)
        }
        .sheet(isPresented: $showCard) {
            KinCardSheet()
                .environmentObject(state)
                .presentationDetents([.fraction(0.92)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSeason) {
            if let season = state.currentSeason {
                ScrollView {
                    SeasonCard(season: season)
                        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 34)
                }
                .background(Theme.paper)
                .environmentObject(state)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .alert("Name your kin", isPresented: $renaming) {
            TextField(kin.displayName, text: $draftName)
                .autocorrectionDisabled()
            Button("Save") {
                state.rename(kin.speciesID, to: draftName)
                draftName = ""
            }
            Button("Cancel", role: .cancel) { draftName = "" }
        } message: {
            Text("You can change this any time.")
        }
        .kinToast(state.toast, bottom: 104)
        .kinAdoptionFlow()
        .onAppear { state.settleFriendship() }
        .onChange(of: state.meetKinRequest) { _, new in
            guard new != nil else { return }
            showShop = false
            showCollection = false
            showWardrobe = false
            showCard = false
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
                                .accessibilityLabel("The \(scene.name) tank")
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
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: Theme.Radius.sheet,
                                                  bottomTrailingRadius: Theme.Radius.sheet,
                                                  style: .continuous))

            VStack(spacing: 2) {
                speechBubble
                namePlate
                stageWord
                KinArtView(speciesID: kin.speciesID,
                           level: kin.level,
                           skin: kin.skinID,
                           animation: state.animation,
                           size: isFirstRun ? 164 : 212)
                    .frame(height: isFirstRun ? 150 : 170)
                    .accessibilityLabel("\(kin.displayName), \(kin.level) of 3 stars")
            }
            // Room under the fins for the care circles' upper halves, and a little water.
            .padding(.bottom, Self.careOverlap + 10)
        }
        .frame(height: 430)
        // Same chip, same gutter, same y as Home. Kin used to carry a separate shop
        // door beside a plain wallet, which put two shop entrances on the tab and
        // sat 4pt off Home's gutter — enough that switching tabs made the corner
        // jump.
        .overlay(alignment: .topTrailing) {
            Button { showShop = true } label: {
                WalletChip(coins: state.coins, onDark: scene.isDark, showsShop: true)
                    // The chip is 34pt tall by design (Home's is the same); the hit
                    // area is 44, grown downward so the chip's y stays Home's.
                    .frame(minHeight: 44, alignment: .top)
                    .contentShape(Rectangle())
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

    /// Nothing here is a guilt trip. The old line ("was fine without you. Mostly.")
    /// was one, and it went on 2026-09-11.
    private var idleCopy: String {
        isFirstRun ? "This one is yours. It's free." : "\(kin.displayName) is around."
    }

    /// One plate: the name and the stars, and a tap renames. It used to be two — a
    /// dashed "Name your kin" pill for an unnamed kin and a plain plate for a named
    /// one — which disagreed about what the thing was.
    private var namePlate: some View {
        Button {
            draftName = kin.name ?? ""
            renaming = true
        } label: {
            HStack(spacing: 9) {
                Text(kin.displayName)
                    .font(Theme.font(14.5, .black))
                    .foregroundStyle(scene.isDark ? .white : Theme.ink)
                StarPips(level: kin.level, size: 13, spacing: 4)
            }
            .padding(.horizontal, 15).padding(.vertical, 7)
            .frame(minHeight: 44)
            .background(GlassPill(onDark: scene.isDark, strong: true).padding(.vertical, 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(kin.displayName), \(kin.level) of 3 stars. Tap to rename")
    }

    /// The friendship word, under the name. Just met, Tankmates, Buddies, Besties,
    /// Old friends — it only ever goes up, and the card explains it in one line.
    private var stageWord: some View {
        Button { showCard = true } label: {
            Text(state.friendshipStage.name)
                .font(Theme.fixedFont(11.5, .black))
                .foregroundStyle(scene.isDark ? Theme.onDarkWarm : Theme.muted)
                .padding(.horizontal, 11).padding(.vertical, 4)
                .frame(minHeight: 44)
                .background(GlassPill(onDark: scene.isDark, strong: false).padding(.vertical, 10))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("You and \(kin.displayName) are \(state.friendshipStage.name.lowercased()). Opens the card")
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

    // MARK: - Doors

    /// Finch's Bag as a row of doors. Every door is open; none is a "?". Decorate
    /// joins the row the day its props land (`KinFlags.decorate`).
    private var doors: some View {
        HStack(spacing: 10) {
            door("Wardrobe", symbol: "tshirt.fill", tint: .coral) { showWardrobe = true }
            if KinFlags.decorate {
                door("Decorate", symbol: "leaf.fill", tint: .mint) { showDecorate = true }
            }
            door("Collection", symbol: "square.grid.2x2.fill", tint: .lilac) { showCollection = true }
            door("Card", symbol: "person.text.rectangle.fill", tint: .gold) { showCard = true }
        }
        .padding(.horizontal, Theme.gutter)
    }

    // The four icons are owed from the icon pipeline (`design/icons/`); until then
    // SF Symbols whose metaphor is literally the thing named stand in.
    private func door(_ title: String, symbol: String, tint: IconTint, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(tint.soft))
                Text(title)
                    .font(Theme.font(12, .heavy))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.cardEdge, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    // MARK: - Season

    /// One row, dated, no countdown. The whole ladder opens as a sheet.
    private func seasonRow(_ season: Season) -> some View {
        let progress = state.game.plus.progress(season)
        return Button { showSeason = true } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(season.name)
                        .font(Theme.font(14.5, .black)).foregroundStyle(Theme.ink)
                    Text("\(progress.rungsClaimed) of \(season.rungs.count) days claimed")
                        .font(Theme.font(11.5, .heavy)).foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 8)
                // A date, not a clock. Nothing here ticks.
                Text("Ends \(SeasonCard.endStamp(season))")
                    .font(Theme.fixedFont(10.5, .black))
                    .foregroundStyle(Theme.bagInk)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(Theme.paperSunk))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .black)).foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(minHeight: 56)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.cardEdge, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.gutter)
        .accessibilityLabel("\(season.name), \(progress.rungsClaimed) of \(season.rungs.count) days claimed, ends \(SeasonCard.endStamp(season))")
    }
}
