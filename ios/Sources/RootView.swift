import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState
    @State private var tab: Tab = .home

    /// Six tabs, and **Shop is deliberately not one of them** — it opens from the coin
    /// chip on Home, where the motivation already is.
    ///
    /// Six is more than the usual iOS advice, and it works here for one reason: every
    /// icon is a full-colour object, so a tab is found by silhouette and colour rather
    /// than by parsing a grey glyph. If the icons are ever reduced to monochrome, this
    /// bar has to be cut to four or five.
    enum Tab: String, CaseIterable {
        case home, focus, games, learn, friends, kin

        var label: String {
            switch self {
            case .home: return "Home"
            case .focus: return "Focus"
            case .games: return "Games"
            case .learn: return "Learn"
            case .friends: return "Friends"
            case .kin: return "Kin"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home: HomeView()
                case .focus: FocusView()
                case .games: GamesView()
                case .learn: LearnView()
                case .friends: FriendsView()
                case .kin: ShopView(title: "Kin")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !state.hideTabBar {
                tabBar.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: state.hideTabBar)
        .background(Theme.paper.ignoresSafeArea())
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Tab.allCases, id: \.self) { t in
                tabButton(t)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .background(
            Theme.tabBar
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Theme.hex(0x281412).opacity(0.06), radius: 11, y: -6)
        )
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 0.5)
        }
    }

    private func tabButton(_ t: Tab) -> some View {
        let active = t == tab
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { tab = t }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if t == .kin {
                        // Exempt from the inactive dimming — a face that dims reads as
                        // an unwell pet.
                        KinChip(color: Theme.species(state.activeChibiID), size: 28)
                    } else {
                        TabIcon(tab: t, size: 27)
                            .opacity(active ? 1 : 0.82)
                            .saturation(active ? 1 : 0.72)
                    }
                }
                .frame(height: 28)

                Text(t.label)
                    .font(Theme.font(10.5, active ? .black : .heavy))
                    .foregroundStyle(active ? Theme.tabActiveInk : Theme.tabInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 7).padding(.bottom, 5)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(active ? Theme.tabActiveFill : .clear))
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
    var color: Color = Slime.body
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle().fill(Slime.belly(for: color).opacity(0.55))
            SlimeView(color: color, level: 1, animation: .idle, size: size * 1.30)
                .offset(y: size * 0.07)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
