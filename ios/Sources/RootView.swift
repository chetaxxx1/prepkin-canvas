import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState
    @State private var tab: Tab = .home
    /// `Theme.font` reads the system text size when a body runs; rebuilding the
    /// tabs when it changes is what makes a Settings change show without a relaunch.
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The tab switch spring, or nothing at all under Reduce Motion.
    private var switchAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)
    }

    /// Five tabs. **Shop is deliberately not one of them** — it opens from the coin
    /// chip on Home, where the motivation already is. Games is not one either since
    /// 2026-09-06: Daily Word and Number Line are the Play section on Learn
    /// (design/hicks-law-plan.md), which took the bar from six to Apple's five.
    ///
    /// Every icon is a full-colour object, so a tab is found by silhouette and colour
    /// rather than by parsing a grey glyph. If the icons are ever reduced to
    /// monochrome, this bar has to be cut again.
    ///
    /// Six since 2026-09-09: Calendar is its own tab, by George's call
    /// (design/CALENDAR-PLAN.md). It sits after Learn so the two school tabs
    /// are neighbours. If the bar ever fails the largest-type sweep, the
    /// fallback is a Today / Week / Month switch on Home, not cutting it.
    enum Tab: String, CaseIterable {
        case home, focus, learn, calendar, friends, kin

        var label: String {
            switch self {
            case .home: return "Home"
            case .focus: return "Focus"
            case .learn: return "Learn"
            case .calendar: return "Calendar"
            case .friends: return "Friends"
            case .kin: return "Kin"
            }
        }
    }

    var body: some View {
        if state.firstRunDone {
            tabs
        } else {
            FirstRunView()
                .transition(.opacity)
        }
    }

    private var tabs: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home: HomeView()
                case .focus: FocusView()
                case .learn: LearnView()
                case .calendar: CalendarView()
                case .friends: FriendsView()
                case .kin: KinView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(typeSize)

            if !state.hideTabBar {
                tabBar.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: state.hideTabBar)
        .background(Theme.paper.ignoresSafeArea())
        .onChange(of: state.meetKinRequest) { _, new in
            guard new != nil else { return }
            withAnimation(switchAnimation) { tab = .kin }
            // Held for one beat so the Kin tab and the shop sheet both see it.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                state.meetKinRequest = nil
            }
        }
        .onChange(of: state.openFriendsRequest) { _, new in
            guard new else { return }
            withAnimation(switchAnimation) { tab = .friends }
            Task { @MainActor in state.openFriendsRequest = false }
        }
        // Sitting down with a friend from their card. The tab switch is Root's; the
        // shift is Focus's, which clears the request once it has started one.
        .onChange(of: state.joinShiftRequest) { _, new in
            guard new != nil else { return }
            withAnimation(switchAnimation) { tab = .focus }
        }
        // Home's Tomorrow line. The tab switch is Root's; the day is Calendar's,
        // which clears the request once it has landed on it.
        .onChange(of: state.openCalendarOn) { _, new in
            guard new != nil else { return }
            withAnimation(switchAnimation) { tab = .calendar }
        }
    }

    // MARK: - Tab bar

    /// A floating bar, in two pieces: a capsule holding the five places you go, and
    /// the kin in a bubble of its own at the right.
    ///
    /// Two pieces rather than six-in-a-row because the kin is not a destination in
    /// the same sense — it is who you are carrying. Given its own bubble it stops
    /// competing with Calendar and Friends for the same reading, and the five that
    /// *are* destinations get room for a legible label.
    ///
    /// Floating, so the page runs under it and the screen keeps its full height.
    /// Anything that scrolls has to end with `Theme.tabClearance` of padding.
    private var tabBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(Tab.allCases.filter { $0 != .kin }, id: \.self) { t in
                    tabButton(t)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .background(barSurface(Capsule(style: .continuous)))

            kinBubble
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    /// Cream, one hairline, one soft shadow. The tab bar and a presented sheet are
    /// the only two things in the app allowed a shadow — everything else is flat on
    /// the page with a hairline, so a shadow always means "this floats".
    private func barSurface<S: InsettableShape>(_ shape: S) -> some View {
        shape
            .fill(Theme.tabBar)
            .shadow(color: Theme.hex(0x281412).opacity(0.14), radius: 18, y: 7)
            .overlay(shape.strokeBorder(Theme.ink.opacity(0.06), lineWidth: 1))
    }

    private var kinBubble: some View {
        let active = tab == .kin
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(switchAnimation) { tab = .kin }
        } label: {
            // Exempt from the inactive dimming — a face that dims reads as an
            // unwell pet.
            KinChip(speciesID: state.activeChibiID, size: 42,
                    plate: Theme.plate(for: state.activeChibiID))
                .frame(width: 58, height: 58)
                .background(barSurface(Circle()))
                .overlay(
                    Circle().strokeBorder(Theme.tabActiveInk.opacity(active ? 0.55 : 0),
                                          lineWidth: 2.5)
                )
        }
        .buttonStyle(TabPressStyle())
        .accessibilityLabel("Kin")
        .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
    }

    private func tabButton(_ t: Tab) -> some View {
        let active = t == tab
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(switchAnimation) { tab = t }
        } label: {
            VStack(spacing: 2) {
                TabIcon(tab: t, size: 25)
                    .opacity(active ? 1 : 0.85)
                    .saturation(active ? 1 : 0.7)
                Text(t.label)
                    .font(Theme.fixedFont(9.5, active ? .black : .heavy))
                    .foregroundStyle(active ? Theme.tabActiveInk : Theme.tabInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(active ? Theme.tabActiveFill : .clear)
                    .padding(.horizontal, 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(TabPressStyle())
        .accessibilityLabel(t.label)
        .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
    }
}

/// Tab press: scale to ~0.94 and back.
private struct TabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// The mascot's face in a circle — used anywhere a small buddy avatar is needed.
/// Crops the traced art to the head.
struct SlimeAvatar: View {
    var speciesID: String = "slime"
    var size: CGFloat = 56

    var body: some View {
        SproutFace(speciesID: speciesID, size: size, plate: Theme.plate(for: speciesID))
    }
}
