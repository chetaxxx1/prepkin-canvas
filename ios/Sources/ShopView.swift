import SwiftUI

struct ShopView: View {
    @EnvironmentObject var state: AppState

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("New buddies")
                        .font(.system(size: 18, weight: .black)).foregroundStyle(Theme.ink)
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(ChibiSpecies.catalog) { species in
                            speciesCard(species)
                        }
                    }

                    Text("Scenes")
                        .font(.system(size: 18, weight: .black)).foregroundStyle(Theme.ink)
                        .padding(.top, 12)
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Scene0.all) { scene in
                            sceneCard(scene)
                        }
                    }

                    Text("Coins come from finishing tasks and focus sessions.")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.dim)
                        .padding(.top, 8)
                }
                .padding(16)
                .padding(.bottom, 104)
            }
            .background(Theme.paper)
            .navigationTitle("Shop")
            .safeAreaInset(edge: .top) {
                HStack {
                    Spacer()
                    CoinBadge(coins: state.coins)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func sceneCard(_ scene: Scene0) -> some View {
        let owned = state.ownedScenes.contains(scene.id)
        let equipped = state.sceneID == scene.id

        return VStack(spacing: 8) {
            Image(scene.asset)
                .resizable()
                .scaledToFill()
                .frame(height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(scene.name).font(.system(size: 15, weight: .black)).foregroundStyle(Theme.ink)

            if equipped {
                Text("Equipped")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Theme.mintDark)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Capsule().fill(Theme.mintSoft))
            } else if owned {
                Button { state.equipScene(scene.id) } label: {
                    Text("Use")
                        .font(.system(size: 12, weight: .heavy))
                        .padding(.horizontal, 16).padding(.vertical, 5)
                        .background(Capsule().fill(Theme.coral))
                        .foregroundStyle(.white)
                }
            } else {
                Button { state.buyScene(scene) } label: {
                    HStack(spacing: 4) {
                        CoinDisc(size: 13)
                        Text("\(scene.price)")
                    }
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Theme.coinDark)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Capsule().fill(Theme.coinSoft))
                }
                .disabled(state.coins < scene.price)
                .opacity(state.coins < scene.price ? 0.5 : 1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Theme.card).shadow(color: .black.opacity(0.05), radius: 8, y: 2))
    }

    private func speciesCard(_ species: ChibiSpecies) -> some View {
        let ownedChibi = state.owned.first { $0.speciesID == species.id }
        let isActive = state.activeChibiID == species.id

        return VStack(spacing: 8) {
            SlimeView(color: Theme.species(species.id),
                      level: ownedChibi?.level ?? 1,
                      animation: isActive ? state.animation : .idle,
                      size: 84)
            Text(species.name).font(.headline).foregroundStyle(Theme.ink)
            if let ownedChibi {
                Text("Lv \(ownedChibi.level)").font(.caption).foregroundStyle(Theme.muted)
                if isActive {
                    Text("Active")
                        .font(.caption.bold())
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Theme.mint.opacity(0.25)))
                        .foregroundStyle(Theme.ink)
                } else {
                    Button { state.setActive(species.id) } label: {
                        Text("Use")
                            .font(.caption.bold())
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(Capsule().fill(Theme.sky))
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Text(" ").font(.caption)
                Button { state.buy(species) } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.hexagongrid.circle.fill")
                        Text("\(species.price)")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(state.coins >= species.price ? Theme.coral : Theme.muted.opacity(0.3)))
                    .foregroundStyle(.white)
                }
                .disabled(state.coins < species.price)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.ink.opacity(0.06), radius: 10, y: 4)
        )
    }
}
