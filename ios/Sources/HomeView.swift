import SwiftUI

/// Home, per Claude Design option 4a, with the Finch-style scene layer:
/// the mascot stands in a furnished room, not on an empty gradient.
struct HomeView: View {
    @EnvironmentObject var state: AppState

    @State private var bubble: String?
    @State private var coinGain: Int?

    private var scene: Scene0 { Scene0.find(state.sceneID) }
    private var screenWidth: CGFloat { UIScreen.main.bounds.width }
    private var sceneHeight: CGFloat { min(screenWidth, 370) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    sceneLayer
                    todayHeader
                    taskList
                    footerLinks
                }
                .padding(.bottom, 104)
            }
            .background(Theme.paper)
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .task {
                await state.syncCanvas()
                showBubble(greeting)
            }
        }
    }

    // MARK: - Scene

    private var sceneLayer: some View {
        ZStack(alignment: .top) {
            // Art is square (1024x1024). Drawn at full screen width and anchored to
            // the bottom, so the mascot's floor is always kept and only ceiling is trimmed.
            Image(scene.asset)
                .resizable()
                .scaledToFill()
                .frame(width: screenWidth, height: screenWidth)
                .frame(width: screenWidth, height: sceneHeight, alignment: .bottom)
                .clipped()

            // Warm glow behind the mascot so it separates from the art.
            RadialGradient(colors: [Color.white.opacity(scene.isDark ? 0.28 : 0.5), .clear],
                           center: .init(x: 0.5, y: 0.8), startRadius: 4, endRadius: 170)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                headerRow
                Spacer(minLength: 0)
                mascotBlock
            }
            .padding(.bottom, 10)
        }
        .frame(height: sceneHeight)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30,
                                          style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            HStack(spacing: 7) {
                Text(state.activeChibi.species.name)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Theme.ink)
                Text("Lv \(state.activeChibi.level)")
                    .font(.system(size: 11.5, weight: .black))
                    .foregroundStyle(Theme.mint)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Capsule().fill(Theme.mintSoft))
            }
            .floatingPill()

            Spacer()

            ZStack(alignment: .top) {
                HStack(spacing: 6) {
                    CoinDisc(size: 18)
                    Text("\(state.coins)")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                }
                .floatingPill()

                if let gain = coinGain {
                    Text("+\(gain)")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Theme.coinDark)
                        .offset(y: -26)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 20)),
                            removal: .opacity.combined(with: .offset(y: -10))))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 64)
    }

    private var mascotBlock: some View {
        VStack(spacing: 10) {
            if let text = bubble {
                Text(text)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.card)
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 3))
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }

            SlimeView(color: Theme.species(state.activeChibiID),
                      level: state.activeChibi.level,
                      animation: state.animation,
                      size: 168)
                .onTapGesture {
                    state.play(.wave)
                    showBubble(greeting)
                }
                .onLongPressGesture { state.play(.dance) }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: bubble)
    }

    private var greeting: String {
        let left = state.tasks.filter { !$0.done }.count
        if state.tasks.isEmpty { return "Nothing due. Enjoy it." }
        if left == 0 { return "All done today! \(state.activeChibi.species.name) is so proud." }
        return "\(state.activeChibi.species.name) is cheering you on — \(left) to go!"
    }

    // MARK: - Tasks

    private var todayHeader: some View {
        HStack {
            Text("Today").font(.system(size: 18, weight: .black)).foregroundStyle(Theme.ink)
            Spacer()
            Text("\(state.tasks.filter(\.done).count) of \(state.tasks.count) done")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private var taskList: some View {
        VStack(spacing: 8) {
            ForEach(state.tasks) { task in
                TaskRow(task: task) { toggle(task) }
            }
        }
        .padding(.horizontal, 20)
    }

    private var footerLinks: some View {
        VStack(spacing: 8) {
            NavigationLink { GradeCalcView() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.coralIcon)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.coralSoft))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Grade calculator")
                            .font(.system(size: 15, weight: .heavy)).foregroundStyle(Theme.ink)
                        Text("What do I need on the final?")
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.dim)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2))
            }
            .buttonStyle(.plain)

            Text("Coins come from finishing tasks and focus sessions.")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.dim)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
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
        showBubble(state.allDone ? "All done today! \(state.activeChibi.species.name) is so proud."
                                 : "Yay! Nice work!", seconds: 2.2)
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
    func floatingPill() -> some View {
        padding(.horizontal, 14).padding(.vertical, 7)
            .background(Capsule().fill(Theme.card)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2))
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
                .font(.system(size: 15, weight: .black))
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

    private var isSchool: Bool { task.kind != .life }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSchool ? "book.fill" : "heart.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isSchool ? Theme.coralIcon : Theme.mint)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSchool ? Theme.coralSoft : Theme.mintSoft))

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                        .strikethrough(task.done)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        CoinDisc(size: 11)
                        Text("+\(task.reward)")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(Theme.coinDark)
                        Text("· \(subtitle)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 4)

                ZStack {
                    Circle()
                        .fill(task.done ? Theme.mint : Theme.paper)
                        .overlay(Circle().strokeBorder(task.done ? .clear : Theme.checkBorder,
                                                       lineWidth: 2.5))
                        .frame(width: 30, height: 30)
                        .shadow(color: task.done ? Theme.mint.opacity(0.4) : .clear, radius: 6, y: 2)
                    if task.done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.card)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2))
            .opacity(task.done ? 0.65 : 1)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: task.done)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let d = task.detail { parts.append(d) }
        if let due = task.dueAt {
            parts.append("due \(due.formatted(.dateTime.weekday().hour().minute()))")
        }
        if task.kind == .canvas { parts.append("from Canvas") }
        if parts.isEmpty { parts.append(task.kind.label) }
        return parts.joined(separator: " · ")
    }
}
