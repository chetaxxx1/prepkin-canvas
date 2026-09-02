import SwiftUI

/// Friends tab. All data here is mock until the friend/social bridge exists (M2).
struct FriendsView: View {
    @EnvironmentObject var state: AppState
    @State private var showStoryStub = false
    @State private var showAddStub = false

    private struct Friend: Identifiable {
        let id = UUID()
        let name: String
        let species: String
        let status: String
        let weekCoins: Int
    }

    private let friends: [Friend] = [
        Friend(name: "Maya", species: "ember", status: "Focused 45 min today", weekCoins: 320),
        Friend(name: "Josh", species: "droplet", status: "Solved the word in 3", weekCoins: 280),
        Friend(name: "Ava", species: "sprout", status: "Finished 'Compound interest'", weekCoins: 210),
        Friend(name: "Sam", species: "slime", status: "4 tasks done", weekCoins: 150),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        Text("Friends")
                            .font(Theme.font(34, .black))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Button { showAddStub = true } label: {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(Theme.card)
                                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add a friend")
                    }
                    .padding(.horizontal, 8).padding(.top, 8)
                    stories
                    weeklyBoard
                    friendList
                }
                .padding(16)
                .padding(.bottom, 104)
            }
            .background(Theme.paper)
            .toolbar(.hidden, for: .navigationBar)
            .alert("Friend sync isn't built yet", isPresented: $showAddStub) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Adding real friends comes with the M2 bridge. Everything on this tab is sample data for now.")
            }
            .alert("Stories are coming", isPresented: $showStoryStub) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Friends will post daily wins here — focus streaks, solved words, finished lessons.")
            }
        }
    }

    private var stories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                storyCircle(name: "You", species: state.activeChibiID, isYou: true)
                ForEach(friends) { f in
                    storyCircle(name: f.name, species: f.species, isYou: false)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func storyCircle(name: String, species: String, isYou: Bool) -> some View {
        Button { showStoryStub = true } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(isYou ? Theme.muted.opacity(0.3) : Theme.coral, lineWidth: 2.5)
                        .frame(width: 64, height: 64)
                    Circle().fill(Theme.species(species).opacity(0.25)).frame(width: 56, height: 56)
                    SproutImage(speciesID: species, level: 3, size: 40)
                        .offset(y: 3)
                        .allowsHitTesting(false)
                }
                Text(name).font(.caption).foregroundStyle(Theme.ink)
            }
        }
        .buttonStyle(.plain)
    }

    private var weeklyBoard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week's coins").font(.headline).foregroundStyle(Theme.ink)
            let rows = (friends.map { ($0.name, $0.species, $0.weekCoins) } + [("You", state.activeChibiID, state.week.coinsEarned)])
                .sorted { $0.2 > $1.2 }
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                HStack {
                    Text("\(i + 1)").font(.subheadline.bold()).foregroundStyle(Theme.muted).frame(width: 22)
                    SproutFace(speciesID: row.1, size: 26, plate: Theme.species(row.1).opacity(0.3))
                    Text(row.0)
                        .fontWeight(row.0 == "You" ? .bold : .regular)
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(row.2)").font(.subheadline.bold()).foregroundStyle(Theme.sun)
                }
                .padding(.vertical, 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var friendList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Friends").font(.headline).foregroundStyle(Theme.ink).padding(.bottom, 6)
            ForEach(friends) { f in
                HStack(spacing: 12) {
                    SproutImage(speciesID: f.species, level: 3, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                        Text(f.status).font(.caption).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                if f.id != friends.last?.id { Divider().padding(.leading, 52) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
