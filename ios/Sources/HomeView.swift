import SwiftUI

/// Home, per `design_handoff_prepkin_home_v2`.
///
/// The one idea the whole screen hangs on: **the page background is the scene's own
/// floor colour.** The illustration simply stops and the value carries on to the
/// bottom of the screen, so there is no seam to hide — no gradient, no rounded card,
/// no shadow. If the art ever changes, re-sample its bottom edge into `tankFloor`.
///
/// The scene is Sprout's fish tank, drawn by the same web page that draws Sprout —
/// see `SproutView`. It replaces the room art, so a bought room no longer changes
/// this screen.
struct HomeView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var bubble: String?
    @State private var coinGain: Int?
    @State private var showDayEditor = false
    @State private var showShop = false
    /// The web page has drawn the tank. Until then a flat floor with a still of the
    /// kin stands in, so a cold launch is never a white block.
    @State private var stageReady = false

    /// Day 1, per `design_handoff_first_run`: the offer cards the kin makes after
    /// the first check-off, in order. Nothing is asked for before that.
    private enum Offer { case notify, canvas }
    @State private var offer: Offer?
    @State private var offerTask: Task<Void, Never>?
    /// Where the student last told Sprout to swim, as a fraction of the tank.
    /// `SproutView` forwards it to the page; he swims there and stops.
    @State private var swimTo: CGPoint?
    /// The band the page will actually let him into, as fractions of the tank.
    /// He goes nowhere Home does not send him — the page's own wandering is off
    /// in embed — so this plus `swimTo` is where he is.
    @State private var swimBand: SproutView.Band?
    /// The emote wheel: where it opened, and which slot the finger is nearest.
    /// `nil` origin means it is closed.
    @State private var wheelAt: CGPoint?
    @State private var wheelPick: Int?
    /// What the finger currently on the tank turned out to be.
    private enum Touch { case none, pressing, swimming, wheeling }
    @State private var touch: Touch = .none
    /// The hold that opens the wheel. Cancelled if the finger moves first.
    @State private var pressTask: Task<Void, Never>?
    /// Coins in flight from a row's reward to the wallet chip.
    @State private var flights: [CoinFlight] = []
    @State private var walletFrame: CGRect = .zero
    @State private var rewardFrames: [String: CGRect] = [:]

    /// The tank Sprout lives in: whichever the student has equipped, so the water
    /// on Home and the water in his room are the same water.
    private var tank: Scene0 { Scene0.find(state.sceneID) }
    /// The tank art's own bottom edge, where the page takes over. Sampled into
    /// `Scene0.floor` by `scripts/cut_ios_tanks.py`.
    private var tankFloor: Color { tank.floor }

    /// The page under the tank, carrying the painting's light on down.
    ///
    /// Matching the handoff colour is not enough on its own: the paintings keep
    /// getting slightly deeper toward the viewer, so a page frozen at one value
    /// reads as a separate surface starting at the seam even though the colour
    /// is identical. Continuing the ramp removes that cue, and it also lifts
    /// contrast under the lowest cards, which sit furthest from the art.
    /// The ramp has to START at the bottom of the tank, not at the top of the
    /// screen. Spanning the whole screen means that by the time the gradient
    /// reaches the band's edge it has already drifted a few levels off the
    /// plate's last row, which puts back the very step this is meant to remove
    /// (measured at 4.9 levels on device). Holding `floor` down to the band and
    /// only then easing keeps the handoff exact.
    private var tankPage: LinearGradient {
        LinearGradient(stops: [.init(color: tank.floor, location: 0),
                               .init(color: tank.floor, location: sceneHeight / screenHeight),
                               .init(color: tank.floorDeep, location: 1)],
                       startPoint: .top, endPoint: .bottom)
    }

    private var screenWidth: CGFloat { UIScreen.main.bounds.width }
    private var screenHeight: CGFloat { UIScreen.main.bounds.height }
    /// The tank. Ten per cent taller than the handoff's 0.76 / 0.35, asked for on
    /// 2026-09-04 — the water now has room for Sprout to actually swim around in
    /// rather than hold one spot.
    private var sceneHeight: CGFloat { min(screenWidth * 0.836, screenHeight * 0.385) }
    /// Where the name and coin chips start. Below the status bar, not at the mock's 20pt.
    private let chipsTop: CGFloat = 64

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sceneBlock
                // Pinned: rows scrolling away under a solid band reads as a list;
                // scrolling away under the scene's hard edge reads as a clipping bug.
                header
                ScrollView {
                    VStack(spacing: 0) {
                        taskList
                        tomorrowLine
                        footerLinks
                    }
                    .padding(.bottom, 88)
                }
                .scrollIndicators(.hidden)
            }
            .coordinateSpace(name: "home")
            .onPreferenceChange(WalletFrameKey.self) { walletFrame = $0 }
            .onPreferenceChange(RewardFrameKey.self) { rewardFrames = $0 }
            .overlay {
                ForEach(flights) { flight in
                    FlyingCoin(flight: flight)
                }
                .allowsHitTesting(false)
            }
            .background(tankPage.ignoresSafeArea())
            .ignoresSafeArea(edges: .top)
            // The tank is pale all the way up, so the clock and the header text are
            // dark. The old dark scheme was for the room art, which was saturated
            // enough to carry white.
            .task {
                await state.syncCanvas()
                showBubble(greeting)
                // Came back with a task already done but the offers unanswered
                // (the app was closed in between): pick up where the day left off.
                if state.tasks.contains(where: \.done) { scheduleOffer(after: 0.6) }
            }
            .sheet(isPresented: $showDayEditor) {
                DayEditorView().environmentObject(state)
            }
            .sheet(isPresented: $showShop) {
                // The coin chip reaches the same shop the Kin tab pushes to, so there
                // is one shop in the app rather than two that drift apart.
                NavigationStack { KinShopView(asSheet: true) }
                    .environmentObject(state)
                    
            }
            // "Meet <kin>" on the adoption card: the shop sheet gets out of the way
            // so the Kin tab underneath can show them.
            .onChange(of: state.meetKinRequest) { _, new in
                if new != nil { showShop = false }
            }
        }
    }

    // MARK: - Scene

    private var sceneBlock: some View {
        ZStack(alignment: .top) {
            // Tank and character come from one opaque web view. Splitting them —
            // native tank behind a see-through web view — is what the design would
            // suggest, but a non-opaque WKWebView composites nothing at all, so the
            // page has to paint the whole scene.
            SproutView(speciesID: state.activeChibiID,
                       level: state.activeChibi.level,
                       skin: state.activeChibi.skinID,
                       animation: state.animation,
                       radius: mascotSize * SproutView.radiusRatio,
                       swimTo: swimTo,
                       tank: tank.id,
                       placeholder: UIColor(tankFloor),
                       reduceMotion: reduceMotion,
                       onReady: { ready in
                           withAnimation(.easeOut(duration: 0.25)) { stageReady = ready }
                       },
                       onLayout: { swimBand = $0 })
                .frame(width: screenWidth, height: sceneHeight)

            if !stageReady {
                // The same plate the page will paint, shown natively at once. The
                // page takes a second or three to boot on a phone; a flat floor
                // colour for that long read as the background loading late.
                Image(tank.asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: sceneHeight, alignment: .bottom)
                    .clipped()
                    .background(tankFloor)
                    .overlay(alignment: .bottom) {
                        SproutImage(speciesID: state.activeChibiID,
                                    level: state.activeChibi.level,
                                    skin: state.activeChibi.skinID,
                                    size: mascotSize)
                            .padding(.bottom, sceneHeight * Self.restLift)
                    }
                    .frame(width: screenWidth, height: sceneHeight)
                    .transition(.opacity)
            }

            // The bubble goes over his head wherever the page has parked him. A
            // fixed height off the floor was measured from the wrong thing: the
            // page stands him `restLift` clear of the floor and steers him by a
            // point inside the drawing, so the pill clipped his tuft at rest, sat
            // on the still's hood at launch, and cut him in half the moment the
            // student sent him up the tank. When he is high enough that a line of
            // bubble no longer fits between him and the chips, it goes under his
            // fins instead — the water below him is empty whenever he is up there.
            if let text = bubble {
                let above = mascotHeadY - (chipsTop + 35) >= Self.bubbleLine
                speechBubble(text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: above ? .bottom : .top)
                    .padding(above ? .bottom : .top,
                             above ? sceneHeight - mascotHeadY + 8
                                   : min(mascotFeetY + 8, sceneHeight - Self.bubbleLine))
            }

            chipsRow

            if let at = wheelAt {
                emoteWheel(at: at)
            }
        }
        .frame(width: screenWidth, height: sceneHeight)
        // Deliberately NOT `.clipped()`. SwiftUI clipping masks the whole subtree,
        // and a masked ancestor stops WKWebView's out-of-process layer from
        // rendering — the tank and Sprout both vanish.
        .contentShape(Rectangle())
        // The tank gesture is a DragGesture(minimumDistance: 0) across the whole scene, so it
        // swallows every touch before the web view sees one. With the costume rail on, hand
        // touches to the subviews instead — otherwise tapping a costume just makes him swim there.
        .gesture(tankGesture, including: sproutShowsCostumeTray ? .subviews : .all)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: bubble)
        // The swim is physics on the page, so the pill travelling with him is a
        // near match rather than a synced one. Still better than a jump cut.
        .animation(.easeOut(duration: 0.55), value: swimTo)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: wheelAt)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: wheelPick)
    }

    // MARK: - Touching the tank
    //
    // One drag gesture does both jobs. Touch and let go and Sprout swims to where
    // you touched; hold and a small wheel of emotes opens under your thumb, and
    // you flick toward one and let go to play it — the TFT wheel, four slots.

    /// The four emotes on the wheel, left to right. Four is the cap: past that the
    /// slots get narrower than a thumb and the flick lands on the wrong one.
    ///
    /// Sleep is deliberately not here. It is a toggle on the web side, and
    /// `AppState.play` drops back to `.idle` after the animation's duration —
    /// which sends the wake script and undoes it a second and a half later.
    private static let wheel: [(anim: ChibiAnimation, icon: String, name: String, angle: Double)] = [
        (.wave, "hand.wave.fill", "Wave", 154),
        (.celebrate, "sparkles", "Cheer", 116),
        (.dance, "music.note", "Dance", 64),
        (.peek, "questionmark", "Curious", 26),
    ]
    private static let wheelRadius: CGFloat = 84
    /// Half a chip at its picked size, plus the ring it sits in. The wheel's
    /// centre has to stay this far from every edge of the tank or a slot is cut
    /// off — which is worse than useless, because you cannot aim at what you
    /// cannot see.
    private static var wheelInset: CGFloat { wheelRadius + 31 + 8 }
    /// How far the thumb has to travel before a slot counts as picked. Inside this
    /// the wheel is open but nothing is chosen, so letting go cancels.
    private static let wheelDeadZone: CGFloat = 30
    /// Past this a touch is a swim rather than the start of a hold.
    private static let slop: CGFloat = 12
    private static let holdDelay = Duration.milliseconds(260)

    /// Slot centres, fanned across the top so the thumb never covers them.
    private static func wheelOffset(_ i: Int) -> CGSize {
        let radians = wheel[i].angle * .pi / 180
        return CGSize(width: cos(radians) * wheelRadius, height: -sin(radians) * wheelRadius)
    }

    /// Which slot a flick points at, or `nil` inside the dead zone.
    private static func wheelSlot(for t: CGSize) -> Int? {
        guard hypot(t.width, t.height) >= wheelDeadZone else { return nil }
        let degrees = atan2(-t.height, t.width) * 180 / .pi
        return wheel.indices.min { abs(angleGap(wheel[$0].angle, degrees))
                                 < abs(angleGap(wheel[$1].angle, degrees)) }
    }

    private static func angleGap(_ a: Double, _ b: Double) -> Double {
        let d = (a - b).truncatingRemainder(dividingBy: 360)
        return d > 180 ? d - 360 : (d < -180 ? d + 360 : d)
    }

    /// A touch turned into the fraction of the tank `SproutView.swimTo` wants.
    ///
    /// Only the top edge is Prepkin's business — Sprout should not park behind the
    /// name and coin chips. Keeping the fins and the glow inside the water is the
    /// page's job, in `RiverSprite.goTo`, which is the only place that knows how
    /// far the drawing actually reaches.
    private func swimTarget(_ p: CGPoint) -> CGPoint {
        // A plain fraction of the tank. Where he may actually stop is the page's
        // call — `swimBounds` there insets for the drawing's reach and for the
        // biggest jump any emote makes, and clamps whatever arrives. The only
        // thing added here is the top: Prepkin puts chips over the water, and the
        // page has no idea they exist.
        CGPoint(x: min(max(p.x / screenWidth, 0), 1),
                y: min(max(p.y, chipsTop + 30) / sceneHeight, 1))
    }

    /// Slide the wheel in from the edges so every slot is on screen. The finger
    /// stays where it is — only the ring moves — because the pick is read from
    /// how far the thumb travels, not from where the chips ended up.
    private func wheelOrigin(_ p: CGPoint) -> CGPoint {
        let inset = Self.wheelInset
        return CGPoint(x: min(max(p.x, inset), screenWidth - inset),
                       y: min(max(p.y, inset), sceneHeight - 12))
    }

    private var tankGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // Wheel is open: the rest of the drag only aims it.
                if wheelAt != nil {
                    wheelPick = Self.wheelSlot(for: value.translation)
                    return
                }
                let moved = hypot(value.translation.width, value.translation.height)
                switch touch {
                case .none:
                    touch = .pressing
                    let at = value.startLocation
                    pressTask = Task {
                        try? await Task.sleep(for: Self.holdDelay)
                        guard !Task.isCancelled else { return }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        touch = .wheeling
                        wheelAt = wheelOrigin(at)
                        wheelPick = nil
                    }
                case .pressing:
                    // Moved before the hold landed, so this is a swim.
                    guard moved > Self.slop else { return }
                    pressTask?.cancel()
                    touch = .swimming
                    swimTo = swimTarget(value.location)
                case .swimming:
                    swimTo = swimTarget(value.location)
                case .wheeling:
                    break
                }
            }
            .onEnded { value in
                pressTask?.cancel()
                pressTask = nil
                let wasWheeling = wheelAt != nil
                let pick = wheelPick
                touch = .none
                wheelAt = nil
                wheelPick = nil
                if wasWheeling {
                    // Let go inside the dead zone and nothing plays — that is the
                    // way out of the wheel without picking.
                    if let pick {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        state.play(Self.wheel[pick].anim)
                    }
                    return
                }
                swimTo = swimTarget(value.location)
                // A plain tap still greets you; a drag is just steering.
                if hypot(value.translation.width, value.translation.height) <= Self.slop {
                    showBubble(greeting)
                }
            }
    }

    private func emoteWheel(at origin: CGPoint) -> some View {
        ZStack {
            Color.black.opacity(0.08).ignoresSafeArea()
            ForEach(Array(Self.wheel.enumerated()), id: \.offset) { i, slot in
                let picked = wheelPick == i
                VStack(spacing: 3) {
                    Image(systemName: slot.icon)
                        .font(.system(size: picked ? 21 : 18, weight: .semibold))
                    Text(slot.name)
                        .font(Theme.font(10, .bold))
                }
                .foregroundStyle(picked ? Color.white : Theme.ink)
                .frame(width: picked ? 62 : 54, height: picked ? 62 : 54)
                .background(
                    Circle()
                        .fill(picked ? Theme.mint : Color.white)
                        .shadow(color: .black.opacity(picked ? 0.22 : 0.12),
                                radius: picked ? 10 : 5, y: picked ? 5 : 2)
                )
                .position(x: origin.x + Self.wheelOffset(i).width,
                          y: origin.y + Self.wheelOffset(i).height)
            }
        }
        .frame(width: screenWidth, height: sceneHeight)
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    private var chipsRow: some View {
        HStack(alignment: .top) {
            // The stars used to sit next to the name. They came out to make room for
            // the tier, and nothing was lost: the level band directly under the tank
            // already says "3 stars · fully grown" in words. This chip is the kin's
            // name. A 14-character name is 218pt on its own, so it yields before the
            // tier or the balance does.
            Text(state.activeChibi.displayName)
                .font(Theme.font(15, .black))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(0)
                .sceneChip(leading: 15, trailing: 15)

            // The league pill used to sit here. Friends is a tab, so it was a second
            // door to the same room (design/hicks-law-plan.md, house rule 4).
            Spacer(minLength: 8)

            ZStack(alignment: .top) {
                coinChip
                if let gain = coinGain {
                    Text("+\(gain)")
                        .font(Theme.font(15, .black))
                        .foregroundStyle(Theme.coinDark)
                        .offset(y: -26)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 20)),
                            removal: .opacity.combined(with: .offset(y: -10))))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, chipsTop)
    }

    /// The Shop entrance. It lives here rather than in the tab bar, which puts the
    /// store where the motivation already is and keeps the bar at five.
    private var coinChip: some View {
        Button { showShop = true } label: {
            HStack(spacing: 7) {
                CoinDisc(size: 19)
                Text("\(state.coins)")
                    .font(Theme.font(16, .black))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Rectangle().fill(Theme.chipDivider).frame(width: 1, height: 16)
                Image(systemName: "bag.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.bagInk)
            }
            .sceneChip(leading: 11, trailing: 13)
            .background(GeometryReader { geo in
                Color.clear.preference(key: WalletFrameKey.self,
                                       value: geo.frame(in: .named("home")))
            })
            // The only nudge toward the shop: shown when the balance can afford at
            // least one thing the student does not already own.
            .overlay(alignment: .topTrailing) {
                if canAffordSomething {
                    Circle().fill(Theme.mint).frame(width: 9, height: 9)
                        .padding(2)
                        .background(Circle().fill(.white))
                        .padding(.top, 3).padding(.trailing, 7)
                }
            }
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .padding(.vertical, -5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(state.coins) coins. Open the shop.")
    }

    private var canAffordSomething: Bool {
        var prices = ChibiSpecies.catalog
            .filter { species in !state.owned.contains { $0.speciesID == species.id } }
            .map(\.price)
        prices += Scene0.all.filter { !state.ownedScenes.contains($0.id) }.map(\.price)
        if let upgrade = state.activeChibi.nextUpgradeCost { prices.append(upgrade) }
        return prices.contains { state.coins >= $0 }
    }

    /// 184 wide at Lv 3, per the handoff — trimmed when a real status bar leaves
    /// less room above the floor than the 390×844 mock had (it budgeted 20pt of
    /// chrome; a notched iPhone spends 99). Smaller chibi levels scale down inside
    /// SproutView, so upgrades stay visible.
    private var mascotSize: CGFloat {
        // Chips, then a line of bubble — measured from where the drawing starts,
        // which is `restLift` up from the floor rather than on it. Only short
        // screens are trimmed by that; from 390pt wide up, 184 still wins.
        let headroom = sceneHeight * (1 - Self.restLift) - chipsTop - 35 - 50
        return min(184, screenWidth * 0.472, headroom * SproutView.aspect)
    }

    /// The page stands him this far off the tank floor, as a fraction of the
    /// tank's height, and the still copies it. Home has to know the number:
    /// `mascotHeight` measures the drawing, not where the page puts it.
    private static let restLift: CGFloat = 0.07
    /// A line of bubble: the pill (14pt on 9 + 9) plus the 8 it keeps off him.
    private static let bubbleLine: CGFloat = 43

    /// The whole drawing, top of the tuft to the bottom of the fins.
    private var mascotHeight: CGFloat {
        mascotSize * SproutView.radiusRatio * SproutView.heightPerRadius
    }

    /// The point the page steers him by, in points down from the top of the tank:
    /// the last place Home sent him, trimmed to the band the page reported. He
    /// stays put between sends, so this is where he is, not where he is heading.
    private var mascotAnchorY: CGFloat {
        let rest = sceneHeight * (1 - Self.restLift)
            - mascotHeight * (1 - SproutView.riseRatio)
        let y = swimTo.map { $0.y * sceneHeight } ?? rest
        guard let band = swimBand else { return y }
        return min(max(y, band.top * sceneHeight), band.bottom * sceneHeight)
    }

    /// Top of his tuft and bottom of his fins, in points down from the top.
    private var mascotHeadY: CGFloat { mascotAnchorY - mascotHeight * SproutView.riseRatio }
    private var mascotFeetY: CGFloat { mascotAnchorY + mascotHeight * (1 - SproutView.riseRatio) }

    private func speechBubble(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(14, .bold))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 3))
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    /// Kept to one line: the bubble only has the gap between the chips and the
    /// mascot's head to live in, and the goals row already carries the count.
    private var greeting: String {
        if state.tasks.isEmpty { return "Nothing due. Enjoy it." }
        // Day 1: the bubble points at the checkbox until one has been tapped.
        if isFirstSession, !state.tasks.contains(where: \.done) { return "Tap one when it's done." }
        let name = state.activeChibi.displayName
        if state.tasks.allSatisfy(\.done) { return "All done. Go outside." }
        return "\(name) is watching. No pressure."
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            levelBand
            VStack(alignment: .leading, spacing: 4) {
                goalsRow
                underGoals
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    /// A translucent tint of the floor, never a new hue — it has to read as a darker
    /// patch of the same surface.
    ///
    /// **No bar.** A capsule that fills as coins arrive is a meter, and at three
    /// stars it was a *full* meter with nothing left to do — a promise the screen
    /// could not keep (PRODUCT.md: no meters). The pips say the stage, the words
    /// say what is left, and neither of them moves. The pips also replace the tile:
    /// three stars next to the word "stars" was the same fact drawn twice.
    private var levelBand: some View {
        HStack(spacing: 11) {
            StarPips(level: state.activeChibi.level, size: 17, spacing: 5)
            Text(levelLabel)
                .font(Theme.font(12.5, .black))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Theme.ink.opacity(0.08)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(starsSpoken). \(levelLabel)")
    }

    /// The pips carry the count, so the words never repeat it. In `HomeCopy` so a
    /// test can read every stage without a view.
    private var levelLabel: String {
        HomeCopy.levelLabel(nextUpgradeCost: state.activeChibi.nextUpgradeCost, coins: state.coins)
    }

    private var starsSpoken: String {
        state.activeChibi.level == 1 ? "1 star" : "\(state.activeChibi.level) stars"
    }

    /// State the goal, never the ratio. "1 of 5 done" makes the four undone ones the
    /// headline; "4 goals left today" is the thing a student can act on.
    private var goalsRow: some View {
        HStack(spacing: 9) {
            Text(goalsLine)
                .font(Theme.font(16, .black))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 8)
            Button { showDayEditor = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Theme.ink.opacity(0.08)))
                    .padding(7)
                    .contentShape(Rectangle())
                    .padding(-7)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit your day")
        }
    }

    private var goalsLine: String {
        if state.tasks.isEmpty { return "Nothing due today" }
        let left = state.tasks.filter { !$0.done }.count
        switch left {
        case 0: return "All goals done today"
        case 1: return "1 goal left today"
        default: return "\(left) goals left today"
        }
    }

    /// One quiet line under the goals row. Never a card, never a button, never an
    /// ask — a statement the student can ignore.
    ///
    /// It does two jobs that used to have no home. When the list is empty the space
    /// between the goals row and the rest of the screen was blank, which reads as a
    /// screen that failed to load rather than a day with nothing due. And when the
    /// laptop's list is a few hours old, only the day editor knew — so a student
    /// looking at four rows at 11 PM had no way to tell whether they were tonight's
    /// four. Both are answered here, in muted type, in one line.
    @ViewBuilder private var underGoals: some View {
        if let line = underGoalsLine {
            Text(line)
                .font(Theme.font(12.5, .bold))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var underGoalsLine: String? {
        HomeCopy.underGoals(hasTasks: !state.tasks.isEmpty, lastList: state.lastCanvasSyncAt)
    }

    // MARK: - Tasks

    private var taskList: some View {
        VStack(spacing: 8) {
            if let offer {
                offerCard(offer)
                    .transition(.opacity.combined(with: .offset(y: 12)))
            }
            ForEach(state.tasks) { task in
                TaskRow(task: task) { toggle(task) }
            }
        }
        .padding(.horizontal, 14)
        .animation(.easeOut(duration: 0.35), value: offer)
    }

    // MARK: - Day 1 offers
    //
    // Cards from the kin, never screens, and never before the first check-off.
    // Notifications first, then Canvas. Each is skipped if already settled.

    private var isFirstSession: Bool { !state.firstRunOffersDone }

    private func scheduleOffer(after seconds: Double) {
        guard isFirstSession, offer == nil else { return }
        offerTask?.cancel()
        offerTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            advanceOffer(from: nil)
        }
    }

    private func advanceOffer(from current: Offer?) {
        let next: Offer?
        switch current {
        case nil: next = state.settings.remindersEnabled ? canvasOrNil : .notify
        case .notify: next = canvasOrNil
        case .canvas: next = nil
        }
        offer = next
        if next == nil { state.markFirstRunOffersDone() }
    }

    /// Skipped once the laptop has actually sent a list.
    private var canvasOrNil: Offer? { state.lastCanvasSyncAt == nil ? .canvas : nil }

    @ViewBuilder private func offerCard(_ which: Offer) -> some View {
        let name = state.activeChibi.displayName
        switch which {
        case .notify:
            offerShell(title: "Want \(name) to check in tomorrow evening?") {
                HStack(spacing: 10) {
                    KinChip(speciesID: state.activeChibiID, size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("From \(name)")
                                .font(Theme.font(12.5, .black)).foregroundStyle(Theme.ink)
                            Text(nudgeTime)
                                .font(Theme.font(12.5, .bold)).foregroundStyle(Theme.muted)
                        }
                        Text("How did today go?")
                            .font(Theme.font(12.5, .semibold)).foregroundStyle(Theme.ink)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10).padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.paper))
            } primary: {
                offerButton("Yes please", primary: true) {
                    Task { await state.setRemindersEnabled(true) }
                    advanceOffer(from: .notify)
                }
            } secondary: {
                offerButton("Not now", primary: false) { advanceOffer(from: .notify) }
            }
        case .canvas:
            offerShell(title: "Want your Canvas homework here?") {
                Text("Takes a laptop. Canvas tasks pay \(TaskKind.canvas.reward).")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } primary: {
                offerButton("Show me", primary: true) {
                    advanceOffer(from: .canvas)
                    showDayEditor = true
                }
            } secondary: {
                offerButton("Not now", primary: false) { advanceOffer(from: .canvas) }
            }
        }
    }

    private func offerShell<Body: View, P: View, S: View>(
        title: String, @ViewBuilder body: () -> Body,
        @ViewBuilder primary: () -> P, @ViewBuilder secondary: () -> S
    ) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(DayEditorView.D.mintTint)
                    .frame(width: 44, height: 44)
                    .overlay(SproutImage(speciesID: state.activeChibiID,
                                         level: state.activeChibi.level,
                                         skin: state.activeChibi.skinID, size: 34)
                        .padding(.bottom, 4))
                Text(title)
                    .font(Theme.font(15.5, .black))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            body()
            HStack(spacing: 10) {
                primary()
                secondary()
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.card)
            .shadow(color: Theme.hex(0x281412).opacity(0.07), radius: 3, y: 2))
    }

    private func offerButton(_ label: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(Theme.font(15, .bold))
                .foregroundStyle(primary ? .white : Theme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(primary ? Theme.coral : DayEditorView.D.field))
        }
        .buttonStyle(.plain)
    }

    private var nudgeTime: String {
        var c = DateComponents()
        c.hour = state.settings.nudgeHour
        let date = Calendar.current.date(from: c) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }

    // MARK: - Tomorrow

    /// What is on tomorrow, in one line under today's list.
    ///
    /// Two titles and a count, never a second list — the point is whether tonight
    /// is the last chance, and a student who wants the rest taps through to the
    /// calendar. Gone entirely when tomorrow is empty: "nothing tomorrow" is not
    /// news, and a row that is always there stops being read.
    @ViewBuilder private var tomorrowLine: some View {
        if let text = state.tomorrowLine {
            Button {
                state.openCalendarOn = DayKey.today().adding(days: 1)
            } label: {
                HStack(spacing: 8) {
                    Text(text)
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.dim)
                }
                .padding(.horizontal, 13)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .accessibilityLabel(text)
            .accessibilityHint("Opens tomorrow in the calendar")
        }
    }

    // TODO: the widget install card. Same shell as the Day 1 offers, shown once
    // after the first coin on the second day:
    //   title     "Want \(name) on your home screen?"
    //   primary   "Show me how"  -> a three-step sheet with pictures
    //   secondary "Not now"
    // Not built: `ios/project.yml` has two targets, the app and its tests, and no
    // widget extension. A card that opens instructions for a widget that cannot be
    // installed is the one thing Home must never do — promise something that is not
    // there. Build the target first, then this card.

    private var footerLinks: some View {
        NavigationLink { GradeCalcView() } label: {
            HStack(spacing: 12) {
                IconTile(icon: "calculator", size: 44)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Grade calculator")
                        .font(Theme.font(15.5, .black)).foregroundStyle(Theme.ink)
                    Text("What do I need on the final?")
                        .font(Theme.font(12.5, .bold)).foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 13).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.hex(0x281412).opacity(0.07), radius: 3, y: 2))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    // MARK: - Behavior

    private func toggle(_ task: DailyTask) {
        if task.done {
            state.uncomplete(task)     // no penalty, no animation
            return
        }
        let firstOfDay = !state.tasks.contains(where: \.done)
        state.complete(task)
        withAnimation(.easeOut(duration: 0.25)) { coinGain = task.reward }
        showBubble(checkBubble(paid: task.reward), seconds: 2.2)
        flyCoins(from: task.id)
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeIn(duration: 0.3)) { coinGain = nil }
        }
        if firstOfDay { scheduleOffer(after: 1.5) }
    }

    /// No exclamation marks. Says what just happened, then who noticed.
    private func checkBubble(paid: Int) -> String {
        let name = state.activeChibi.displayName
        if state.allDone {
            return state.tasks.count == 3 ? "All three. \(name) noticed."
                                          : "All done. \(name) noticed."
        }
        return "That's \(paid) coins in the wallet."
    }

    /// Three discs from the row's reward to the wallet chip. The chip is also the
    /// shop door, which is the point.
    private func flyCoins(from taskID: String) {
        // Reduce Motion: the wallet still counts up; nothing crosses the screen.
        guard !reduceMotion else { return }
        guard let from = rewardFrames[taskID], walletFrame != .zero else { return }
        let start = CGPoint(x: from.midX, y: from.midY)
        let end = CGPoint(x: walletFrame.minX + 20, y: walletFrame.midY)
        let batch = (0..<3).map { CoinFlight(index: $0, from: start, to: end) }
        flights += batch
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            flights.removeAll { f in batch.contains { $0.id == f.id } }
        }
    }

    @State private var bubbleToken = UUID()
    private func showBubble(_ text: String, seconds: Double = 3.5) {
        bubble = text
        let token = UUID(); bubbleToken = token
        Task {
            try? await Task.sleep(for: .seconds(seconds))
            if bubbleToken == token { bubble = nil }
        }
    }
}

// MARK: - Pieces

private extension View {
    /// The white pill that floats on the scene art.
    func sceneChip(leading: CGFloat, trailing: CGFloat) -> some View {
        padding(.leading, leading).padding(.trailing, trailing).padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.95))
                .shadow(color: Theme.hex(0x281923).opacity(0.16), radius: 6, y: 3))
    }
}

struct CoinDisc: View {
    var size: CGFloat = 18
    var body: some View {
        Circle()
            .fill(Theme.coin)
            .overlay(Circle().strokeBorder(Theme.coinBorder, lineWidth: size * 0.14))
            .frame(width: size, height: size)
    }
}

struct CoinBadge: View {
    let coins: Int
    var body: some View {
        HStack(spacing: 6) {
            CoinDisc(size: 18)
            Text("\(coins)")
                .font(Theme.font(15, .black))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .animation(.snappy, value: coins)
        }
        .padding(.horizontal, 14).padding(.vertical, 7)
        .background(Capsule().fill(Theme.card).shadow(color: .black.opacity(0.08), radius: 8, y: 2))
    }
}

private struct TaskRow: View {
    let task: DailyTask
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                IconTile(icon: task.category.rawValue, size: 44)

                VStack(alignment: .leading, spacing: 1) {
                    // Two lines, not one: three "Quiz - Computing Servi…" rows in a row
                    // were the same string once truncated.
                    Text(task.title)
                        .font(Theme.font(15.5, .black))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    // Course and full due date only. The reward has its own column.
                    Text(subtitle)
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    HStack(spacing: 3) {
                        CoinDisc(size: 13)
                        Text("\(task.reward)")
                            .font(Theme.font(13, .black))
                            .foregroundStyle(Theme.coinDark)
                    }
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: RewardFrameKey.self,
                                               value: [task.id: geo.frame(in: .named("home"))])
                    })
                    checkbox
                }
            }
            .padding(.horizontal, 13).padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.hex(0x281412).opacity(0.07), radius: 3, y: 2))
            // Finished rows just fade. No strikethrough — done is not cancelled.
            .opacity(task.done ? 0.62 : 1)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: task.done)
    }

    private var checkbox: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(task.done ? Theme.check : Theme.checkFill)
            .overlay {
                if task.done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                } else {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Theme.checkBorder, lineWidth: 2.5)
                }
            }
            .frame(width: 33, height: 33)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let d = task.detail { parts.append(d) }
        if let due = task.dueAt {
            parts.append("due \(due.formatted(.dateTime.weekday(.abbreviated).hour().minute()))")
        }
        if parts.isEmpty {
            parts.append(task.kind == .life ? "Life care" : task.kind.label)
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Coin flight

private struct WalletFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    /// Last **non-empty** wins. A plain `value = nextValue()` lets a sibling subtree
    /// that publishes nothing fold its `.zero` default in over the chip's real frame,
    /// which left `walletFrame` at zero and made `flyCoins` bail every time.
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

private struct RewardFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct CoinFlight: Identifiable {
    let id = UUID()
    let index: Int
    let from: CGPoint
    let to: CGPoint
}

/// One disc, 0.9s on a (.3,.7,.3,1) curve, staggered 80ms by index, fading out
/// over the last third so it lands in the wallet rather than on top of it.
private struct FlyingCoin: View {
    let flight: CoinFlight
    @State private var flown = false
    @State private var faded = false

    var body: some View {
        CoinDisc(size: 16)
            .scaleEffect(flown ? 0.6 : 1)
            .opacity(faded ? 0 : 1)
            .position(flown ? flight.to : flight.from)
            .onAppear {
                let delay = Double(flight.index) * 0.08
                withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.9).delay(delay)) {
                    flown = true
                }
                withAnimation(.easeIn(duration: 0.3).delay(delay + 0.6)) { faded = true }
            }
    }
}
