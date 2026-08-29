import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState
    @State private var tab: Tab = .home

    /// The five icon tabs. Shop is not here — it lives in the mascot circle.
    enum Tab: String, CaseIterable {
        case home, focus, games, learn, friends, shop

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .focus: return "clock.fill"
            case .games: return "gamecontroller.fill"
            case .learn: return "book.fill"
            case .friends: return "person.2.fill"
            case .shop: return "bag.fill"
            }
        }

        static var pillTabs: [Tab] { [.home, .focus, .games, .learn, .friends] }
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
                case .shop: ShopView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !state.hideTabBar {
                tabBar.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: state.hideTabBar)
        .background(Theme.paper)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Floating pill + mascot circle

    private var tabBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                ForEach(Tab.pillTabs, id: \.self) { t in
                    iconButton(t)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.ink)
                    .shadow(color: .black.opacity(0.22), radius: 16, y: 6))

            mascotButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
        // Fade page content out beneath the floating bar instead of letting
        // cards slide under it edge-first.
        .background(
            LinearGradient(colors: [Theme.paper.opacity(0), Theme.paper.opacity(0.92), Theme.paper],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 150)
                .allowsHitTesting(false),
            alignment: .bottom)
    }

    private func iconButton(_ t: Tab) -> some View {
        let active = t == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { tab = t }
        } label: {
            Image(systemName: t.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(active ? .white : Color.white.opacity(0.42))
                .frame(width: 44, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(active ? Theme.coral : .clear))
        }
        .buttonStyle(.plain)
    }

    private var mascotButton: some View {
        let active = tab == .shop
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { tab = .shop }
        } label: {
            SlimeAvatar(color: Theme.species(state.activeChibiID), size: 56)
                .overlay(
                    Circle().strokeBorder(active ? Theme.coral : Color.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.18), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
    }
}

/// The mascot's face in a circle — used as the Shop tab button and anywhere a
/// small buddy avatar is needed. Crops the traced art to the head.
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
