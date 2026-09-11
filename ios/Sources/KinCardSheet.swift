import SwiftUI

/// The Card door on the Kin tab: the adoption certificate, kept current, with
/// Share under it. Finch's pet profile (age in days, friendship level, friend code,
/// three little growth stats, share top right) in the shape of the keepsake the
/// adoption ceremony already hands out, so there is one card in the app and it is
/// the same card on day one and on day two hundred.
///
/// Share renders the kin on its tank plate at story size. That picture is the free
/// marketing the launch plan wants, and it carries no coin count and no number but
/// the day — nothing on it can read as a score.
struct KinCardSheet: View {
    @EnvironmentObject var state: AppState

    @State private var share: ShareFile?

    private var kin: OwnedChibi { state.activeChibi }
    private var scene: Scene0 { Scene0.find(state.sceneID) }
    private var serial: Int {
        (state.owned.firstIndex { $0.speciesID == kin.speciesID } ?? 0) + 1
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AdoptionCard(species: kin.species, kin: kin,
                             daysTogether: state.daysTogether(kin),
                             stats: KinCardStats(since: kin, in: state.game),
                             serial: serial,
                             stage: state.friendshipStage,
                             friendCode: state.friendCode,
                             firsts: state.game.firsts.rows(for: kin.speciesID))

                Button {
                    let image = StoryCard.render(kin: kin, scene: scene,
                                                 daysTogether: state.daysTogether(kin),
                                                 stage: state.friendshipStage)
                    share = ShareFile.write(image, named: "\(kin.displayName)-day-\(state.daysTogether(kin)).png")
                } label: {
                    HStack(spacing: 8) {
                        KinIcon(.share, size: 17, color: .white)
                        Text("Share").font(Theme.font(15, .black))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(minHeight: 50)
                    .background(Capsule().fill(Theme.coral)
                        .shadow(color: Theme.coral.opacity(0.35), radius: 16, y: 6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share \(kin.displayName)'s card")
            }
            .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 34)
        }
        .scrollIndicators(.hidden)
        .background(Theme.hex(0xF1EADC))
        .sheet(item: $share) { ShareImageSheet(url: $0.url) }
    }
}

/// A rendered picture, written to a file, on its way to the share sheet. A file
/// rather than a `UIImage`: the sheet then shows the picture itself as its preview
/// and every target (Messages, Files, Save Image) gets a named PNG.
struct ShareFile: Identifiable {
    let url: URL
    var id: String { url.path }

    static func write(_ image: UIImage, named name: String) -> ShareFile? {
        guard let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return ShareFile(url: url)
        } catch {
            return nil
        }
    }
}

/// The system share sheet for one picture. Raised from a button rather than a
/// `ShareLink` so the picture is drawn on the tap and not on every body pass.
struct ShareImageSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - The story image

/// 1080 × 1920: the kin on its tank plate, the name plate, the day count and the
/// friendship word, on paper. The plate sits in the story as a whole 4:3 card
/// rather than bled to the edges, because a 9:16 crop of a 4:3 painting cuts both
/// props off — the one thing every tank plate is composed to keep in frame.
struct StoryCard: View {
    let kin: OwnedChibi
    let scene: Scene0
    let daysTogether: Int
    let stage: FriendshipStage

    static let size = CGSize(width: 1080, height: 1920)
    /// 4:3, the plate's own shape, with 40pt of paper each side.
    private static let plate = CGSize(width: 1000, height: 750)

    var body: some View {
        ZStack {
            Theme.paper
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack(alignment: .bottom) {
                    Image(scene.asset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: Self.plate.width, height: Self.plate.height)
                        .clipped()

                    // Same lift off the floor as Home's still: `restLift` of the band.
                    SproutImage(speciesID: kin.speciesID, level: kin.level, skin: kin.skinID, size: 560)
                        .padding(.bottom, Self.plate.height * 0.07)

                    VStack(spacing: 18) {
                        HStack(spacing: 14) {
                            Text(kin.displayName)
                                .font(.system(size: 44, weight: .black, design: .rounded))
                                .foregroundStyle(scene.isDark ? .white : Theme.ink)
                            StarPips(level: kin.level, size: 34, spacing: 10)
                        }
                        .padding(.horizontal, 36).padding(.vertical, 18)
                        .background(GlassPill(onDark: scene.isDark, strong: true))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 48)
                }
                .frame(width: Self.plate.width, height: Self.plate.height)
                .clipShape(RoundedRectangle(cornerRadius: 56, style: .continuous))
                .shadow(color: Theme.hex(0x2E2822).opacity(0.14), radius: 40, y: 16)

                Text("Day \(daysTogether) together")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 72)

                Text(stage.name)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 40).padding(.vertical, 16)
                    .background(Capsule().fill(Theme.card))
                    .overlay(Capsule().strokeBorder(Theme.cardEdge, lineWidth: 2))
                    .padding(.top, 24)

                Spacer(minLength: 0)

                HStack(spacing: 16) {
                    Circle().fill(Theme.slime).frame(width: 22, height: 22)
                    Text("Prepkin Canvas")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.bottom, 96)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    /// Draws the card at 1080 × 1920 pixels. Falls back to a plain paper card if the
    /// renderer has nothing, which it never should, rather than sharing nil.
    @MainActor
    static func render(kin: OwnedChibi, scene: Scene0, daysTogether: Int, stage: FriendshipStage) -> UIImage {
        let renderer = ImageRenderer(content: StoryCard(kin: kin, scene: scene,
                                                        daysTogether: daysTogether, stage: stage))
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(size)
        return renderer.uiImage ?? UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor(Theme.paper).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
