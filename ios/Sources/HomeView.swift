import SwiftUI

/// Home, per `design_handoff_prepkin_home_v2`.
///
/// The one idea the whole screen hangs on: **the page background is the scene's own
/// floor colour.** The illustration simply stops and the value carries on to the
/// bottom of the screen, so there is no seam to hide — no gradient, no rounded card,
/// no shadow. If the art ever changes, re-sample its bottom edge into `Scene0.floor`.
struct HomeView: View {
    @EnvironmentObject var state: AppState

    @State private var bubble: String?
    @State private var coinGain: Int?
    @State private var showDayEditor = false
    @State private var showShop = false

    private var scene: Scene0 { Scene0.find(state.sceneID) }
    private var screenWidth: CGFloat { UIScreen.main.bounds.width }
    private var screenHeight: CGFloat { UIScreen.main.bounds.height }
    private var sceneHeight: CGFloat { min(screenWidth * 0.76, screenHeight * 0.35) }
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
                        footerLinks
                    }
                    .padding(.bottom, 88)
                }
                .scrollIndicators(.hidden)
            }
            .background(scene.floor.ignoresSafeArea())
            .ignoresSafeArea(edges: .top)
            // The scene art runs under the status bar. White content over the scrim
            // reads on every scene; a per-scene flip does not, because averaging busy
            // art still lands the clock on a dark bookshelf.
            .preferredColorScheme(.dark)
            .task {
                await state.syncCanvas()
                showBubble(greeting)
            }
            .sheet(isPresented: $showDayEditor) {
                DayEditorView().environmentObject(state).preferredColorScheme(.light)
            }
            .sheet(isPresented: $showShop) {
                ShopView().environmentObject(state).preferredColorScheme(.light)
            }
        }
    }

    // MARK: - Scene

    private var sceneBlock: some View {
        ZStack(alignment: .top) {
            // Square art, drawn at full screen width and anchored to the bottom, so
            // the mascot's floor is always kept and only ceiling is trimmed.
            Image(scene.asset)
                .resizable()
                .scaledToFill()
                .frame(width: screenWidth, height: screenWidth)
                .frame(width: screenWidth, height: sceneHeight, alignment: .bottom)
                .clipped()

            // A soft top scrim so the clock and the white chips stay readable over
            // whatever the art happens to put up there. This is NOT the seam the
            // handoff bans — that rule is about the bottom edge, which stays flat.
            LinearGradient(colors: [.black.opacity(0.32), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: chipsTop + 48)
                .frame(maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)

            // Drawn after the art and fully opaque. Finch dissolves rooms, never pets.
            VStack(spacing: 4) {
                if let text = bubble { speechBubble(text) }
                mascot
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 2)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: bubble)

            chipsRow
        }
        .frame(width: screenWidth, height: sceneHeight)
        .clipped()
    }

    private var chipsRow: some View {
        HStack(alignment: .top) {
            HStack(spacing: 8) {
                Text(state.activeChibi.species.name)
                    .font(Theme.font(15, .black))
                    .foregroundStyle(Theme.ink)
                Text("Lv \(state.activeChibi.level)")
                    .font(Theme.font(11.5, .black))
                    .foregroundStyle(Theme.mintDark)
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(Capsule().fill(Theme.mintSoft))
            }
            .sceneChip(leading: 15, trailing: 15)

            Spacer()

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
    /// store where the motivation already is and keeps the bar at six.
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

    /// 184 wide at Lv 3, per the handoff — trimmed when a real status bar leaves less
    /// room above the floor than the 390×844 mock had (it budgeted 20pt of chrome; a
    /// notched iPhone spends 99). Smaller chibi levels scale down inside SlimeView, so
    /// upgrades stay visible.
    private var mascotSize: CGFloat {
        let headroom = sceneHeight - chipsTop - 35 - 50   // chips, then a line of bubble
        return min(184, screenWidth * 0.472, headroom * Slime.aspect)
    }

    private var mascot: some View {
        SlimeView(color: Theme.species(state.activeChibiID),
                  level: state.activeChibi.level,
                  animation: state.animation,
                  size: mascotSize)
            // SlimeView's frame is taller than the character. Collapse the slack on
            // both sides so the feet land on the floor and the bubble sits on the head.
            .padding(.vertical, -SlimeView.footInset(size: mascotSize,
                                                     level: state.activeChibi.level))
            .onTapGesture(count: 2) { state.play(.peek) }
            .onTapGesture {
                state.play(.wave)
                showBubble(greeting)
            }
            .onLongPressGesture { state.play(.dance) }
    }

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
        let name = state.activeChibi.species.name
        if state.tasks.allSatisfy(\.done) { return "All done today!" }
        return "\(name) is cheering you on!"
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            levelBand
            goalsRow
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    /// A translucent tint of the floor, never a new hue — it has to read as a darker
    /// patch of the same surface.
    private var levelBand: some View {
        HStack(spacing: 11) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(Theme.hex(0x7A4A12))
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Theme.coin))

            VStack(alignment: .leading, spacing: 5) {
                Text(levelLabel)
                    .font(Theme.font(12.5, .black))
                    .foregroundStyle(Theme.onDarkWarm)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.22))
                        Capsule().fill(Theme.coin)
                            .frame(width: max(0, geo.size.width * levelProgress))
                    }
                }
                .frame(height: 7)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.black.opacity(0.17)))
    }

    private var levelLabel: String {
        let chibi = state.activeChibi
        guard let cost = chibi.nextUpgradeCost else { return "Lv \(chibi.level) · fully grown" }
        let left = max(0, cost - state.coins)
        if left == 0 { return "Lv \(chibi.level) · ready for Lv \(chibi.level + 1)" }
        return "Lv \(chibi.level) · \(left) to Lv \(chibi.level + 1)"
    }

    private var levelProgress: Double {
        guard let cost = state.activeChibi.nextUpgradeCost, cost > 0 else { return 1 }
        return min(1, Double(state.coins) / Double(cost))
    }

    /// State the goal, never the ratio. "1 of 5 done" makes the four undone ones the
    /// headline; "4 goals left today" is the thing a student can act on.
    private var goalsRow: some View {
        HStack(spacing: 9) {
            Image(systemName: "calendar")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text(goalsLine)
                .font(Theme.font(16, .black))
                .foregroundStyle(.white)
            Spacer(minLength: 8)
            Button { showDayEditor = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.black.opacity(0.17)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit your day")
        }
    }

    private var goalsLine: String {
        if state.tasks.isEmpty { return "Nothing due today" }
        let left = state.tasks.filter { !$0.done }.count
        switch left {
        case 0: return "All goals done today!"
        case 1: return "1 goal left today"
        default: return "\(left) goals left today"
        }
    }

    // MARK: - Tasks

    private var taskList: some View {
        VStack(spacing: 8) {
            ForEach(state.tasks) { task in
                TaskRow(task: task) { toggle(task) }
            }
        }
        .padding(.horizontal, 14)
    }

    private var footerLinks: some View {
        NavigationLink { GradeCalcView().preferredColorScheme(.light) } label: {
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Theme.coralDeep))
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
        state.complete(task)
        withAnimation(.easeOut(duration: 0.25)) { coinGain = task.reward }
        showBubble(state.allDone ? "All done today!" : "Yay! Nice work!", seconds: 2.2)
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeIn(duration: 0.3)) { coinGain = nil }
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
                CategoryIcon(category: task.category, size: 32)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Theme.tile))
                    .overlay(Circle().strokeBorder(Theme.tileRing, lineWidth: 1.5))

                VStack(alignment: .leading, spacing: 1) {
                    Text(task.title)
                        .font(Theme.font(15.5, .black))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
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
