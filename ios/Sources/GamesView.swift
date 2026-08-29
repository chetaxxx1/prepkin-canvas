import SwiftUI

struct GamesView: View {
    @EnvironmentObject var state: AppState

    // Mock until the friend bridge exists (M2).
    private let board: [(String, Int)] = [
        ("Maya", 2), ("Josh", 3), ("Ava", 4), ("Sam", 5),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NavigationLink { WordleView() } label: {
                        gameCard(emoji: "🟩", title: "Daily Word",
                                 subtitle: "One word a day · +30 coins", locked: false)
                    }
                    .buttonStyle(.plain)

                    gameCard(emoji: "⚔️", title: "Versus",
                             subtitle: "Word battles with friends · needs friend sync (M2)",
                             locked: true)

                    leaderboard
                }
                .padding(16)
                .padding(.bottom, 104)
            }
            .background(Theme.paper)
            .navigationTitle("Games")
        }
    }

    private func gameCard(emoji: String, title: String, subtitle: String, locked: Bool) -> some View {
        HStack(spacing: 14) {
            Text(emoji).font(.system(size: 34))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(Theme.ink)
                Text(subtitle).font(.caption).foregroundStyle(Theme.muted)
            }
            Spacer()
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .foregroundStyle(Theme.muted)
        }
        .card()
        .opacity(locked ? 0.6 : 1)
    }

    private var leaderboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's leaderboard")
                .font(.headline).foregroundStyle(Theme.ink)
            Text("Sample data until friend sync lands.")
                .font(.caption).foregroundStyle(Theme.muted)
            ForEach(Array(board.enumerated()), id: \.offset) { i, entry in
                HStack {
                    Text("\(i + 1)").font(.subheadline.bold()).foregroundStyle(Theme.muted)
                        .frame(width: 22)
                    Circle().fill(Theme.species(ChibiSpecies.catalog[i % 4].id))
                        .frame(width: 28, height: 28)
                    Text(entry.0).foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(entry.1)/6").font(.subheadline.bold()).foregroundStyle(Theme.mint)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
