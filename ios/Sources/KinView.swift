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
                    togetherStrip.padding(.top, 22)
                    collectionCard.padding(.top, 16)
                }
                .padding(.bottom, 120)
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
                    Image(scene.asset)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 470, alignment: .bottom)
                        .clipped()
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
                           animation: state.animation,
                           size: isFirstRun ? 164 : 212)
                    .frame(height: isFirstRun ? 158 : 200)
                starPlate
            }
            .padding(.bottom, 16)
        }
        .frame(height: 430)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 10) {
                Button { showShop = true } label: {
                    KinIcon(.shopDoor, size: 21, color: scene.isDark ? .white : Theme.ink)
                        .frame(width: 40, height: 40)
                        .background(GlassPill(onDark: scene.isDark, strong: false))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Shop")

                WalletChip(coins: state.coins, onDark: scene.isDark)
                    .onTapGesture { showShop = true }
            }
            .padding(.trailing, 24)
            .padding(.top, 58)
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
        isFirstRun ? "This one is yours. It's free." : "\(kin.displayName) is glad you came by."
    }

    /// An unnamed kin gets a dashed invitation instead of a plate, because a plate
    /// reading "Slime" looks like a label rather than a name.
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

    // MARK: - Together since

    /// Real numbers, and every one of them only ever goes up. On day one the strip
    /// says so in words instead of printing three zeros, because a row of zeros reads
    /// as failure on the one strip whose whole promise is that it climbs.
    /// Counted from the day this kin arrived, like its card.
    private var mine: LifetimeStats { state.game.stats(since: kin) }

    @ViewBuilder private var togetherStrip: some View {
        if mine == LifetimeStats() {
            VStack(spacing: 4) {
                Text("Day 1 together")
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
        var out: [(String, String)] = [("\(state.daysTogether(kin))", "days together")]
        if let canvas = state.game.canvasFinished(since: kin) {
            out.append(("\(canvas)", "assignments"))
        }
        let h = mine.focusMinutes / 60, m = mine.focusMinutes % 60
        out.append((h > 0 ? "\(h)h \(m)m" : "\(m)m", "focused"))
        if out.count < 3 { out.append(("\(mine.lessonsRead)", "lessons")) }
        return out
    }

    // MARK: - Collection card

    private var collectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { showCollection = true } label: {
                HStack(spacing: 8) {
                    KinIcon(.dock, size: 18, color: Theme.ink)
                    Text(isFirstRun ? "Five more to meet" : "Collection")
                        .font(Theme.font(15, .black)).foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(state.owned.count) of \(ChibiSpecies.catalog.count)")
                        .font(Theme.font(12, .heavy)).foregroundStyle(Theme.muted)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .black)).foregroundStyle(Theme.dim)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                ForEach(ChibiSpecies.catalog) { species in
                    let mine = state.ownedKin(species.id)
                    Button { detail = species } label: {
                        KinArtView(speciesID: species.id, level: mine?.level ?? 1, size: 42)
                            .frame(height: 38)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(mine == nil ? Theme.unowned : Theme.hex(0xF6F1E6))
                                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .strokeBorder(borderColor(species), lineWidth: 2)))
                    }
                    .buttonStyle(.plain)
                }
            }

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
