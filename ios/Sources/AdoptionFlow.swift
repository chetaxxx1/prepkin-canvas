import SwiftUI

// Buying a kin, as one path: adopt (from the kin sheet) → arrival → naming → certificate. Every step
// after the first can be left, and leaving keeps the kin. Nothing here can be lost
// by backing out.

extension View {
    func kinAdoptionFlow() -> some View { modifier(KinAdoptionFlow()) }
}

struct KinAdoptionFlow: ViewModifier {
    @EnvironmentObject var state: AppState

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: sheetBinding) {
                if let flow = state.adoption {
                    Group {
                        switch flow.step {
                        case .confirm: BuyConfirmSheet(species: flow.species)
                        case .naming: NameKinSheet(species: flow.species)
                        case .certificate: CertificateSheet(species: flow.species)
                        case .arrival: EmptyView()
                        }
                    }
                    // Sized to what is on them. Both used to open full height with
                    // the bottom half empty.
                    .presentationDetents([flow.step == .certificate ? .fraction(0.9) : .fraction(0.62)])
                    .presentationDragIndicator(.visible)
                }
            }
            .fullScreenCover(isPresented: arrivalBinding) {
                if let flow = state.adoption { ArrivalScreen(species: flow.species) }
            }
    }

    private var sheetBinding: Binding<Bool> {
        Binding(get: { state.adoption != nil && state.adoption?.step != .arrival },
                set: { if !$0 { state.endAdoption() } })
    }

    private var arrivalBinding: Binding<Bool> {
        Binding(get: { state.adoption?.step == .arrival },
                set: { if !$0 { state.endAdoption() } })
    }
}

// MARK: - 1. Confirm

/// Three numbers, in the order a student actually asks them: what it normally costs,
/// what it costs today, and what is left afterwards. That last line is the question
/// the old shop never answered.
struct BuyConfirmSheet: View {
    @EnvironmentObject var state: AppState
    let species: ChibiSpecies

    private var price: Int { state.currentPrice("kin:\(species.id)") }
    private var discounted: Bool { price < species.price }

    var body: some View {
        VStack(spacing: 14) {
            TierPlate(tier: species.tier).padding(.top, 22)
            KinArtView(speciesID: species.id, size: 180).frame(height: 168)
            Text(species.name).font(Theme.font(27, .black)).foregroundStyle(Theme.ink)
            Text("Starts at 1 star. You'll name it next.")
                .font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)

            VStack(spacing: 0) {
                row("Collection price", value: "\(species.price)", struck: discounted)
                if discounted {
                    row("Today's pick · 20% off", value: "\(price)", emphasis: true)
                }
                Rectangle().fill(Theme.hairline).frame(height: 1).padding(.vertical, 4)
                row("Wallet after", value: "\(state.coins - price)", emphasis: true)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.card))

            Button { state.confirmAdoption() } label: {
                HStack(spacing: 7) {
                    Text("Adopt \(species.name)").font(Theme.font(15, .black))
                    CoinDisc(size: 15)
                    Text("\(price)").font(Theme.font(15, .black))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(Capsule().fill(Theme.coral)
                    .shadow(color: Theme.coral.opacity(0.35), radius: 16, y: 6))
            }
            .buttonStyle(.plain)
            .disabled(state.coins < price)
            .opacity(state.coins < price ? 0.5 : 1)

            Button { state.endAdoption() } label: {
                Text("Not now").font(Theme.font(14, .heavy)).foregroundStyle(Theme.muted)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24).padding(.bottom, 34)
        .frame(maxWidth: .infinity)
        .background(Theme.paper)
    }

    private func row(_ label: String, value: String, struck: Bool = false, emphasis: Bool = false) -> some View {
        HStack {
            Text(label).font(Theme.font(13, .bold)).foregroundStyle(Theme.muted)
            Spacer()
            HStack(spacing: 5) {
                CoinDisc(size: emphasis ? 14 : 12)
                Text(value)
                    .font(Theme.font(emphasis ? 16 : 13, .black))
                    .foregroundStyle(struck ? Theme.dim : Theme.ink)
                    .strikethrough(struck)
            }
        }
        .padding(.vertical, 5)
    }
}

// MARK: - 2. Arrival

/// The warmest moment in the app: no header, no wallet, no tab bar. Rings borrowed
/// from the tier, confetti borrowed from the Home celebration.
struct ArrivalScreen: View {
    @EnvironmentObject var state: AppState
    let species: ChibiSpecies

    @State private var landed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tint: Color { Theme.tier(species.tier) }

    var body: some View {
        ZStack {
            RadialGradient(colors: [tint.opacity(0.22), Theme.paper],
                           center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 340)
                .ignoresSafeArea()

            ForEach([330.0, 246.0, 166.0], id: \.self) { d in
                Circle()
                    .strokeBorder(tint.opacity(d == 166 ? 0.44 : 0.30), lineWidth: 2)
                    .background(d == 166 ? Circle().fill(tint.opacity(0.18)) : nil)
                    .frame(width: d, height: d)
                    .offset(y: -60)
            }

            if !reduceMotion { Confetti(active: landed).offset(y: -80) }

            VStack(spacing: 12) {
                KinArtView(speciesID: species.id, animation: .celebrate,
                           expression: .delight, size: 248)
                    .frame(height: 232)
                    .scaleEffect(landed || reduceMotion ? 1 : 0.8)
                    .opacity(landed || reduceMotion ? 1 : 0)

                TierPlate(tier: species.tier)
                Text("\(species.name) is here.")
                    .font(Theme.font(34, .black)).foregroundStyle(Theme.ink)
                Text(arrivalLine)
                    .font(Theme.font(13.5, .bold)).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)

                Button { state.advanceAdoption(to: .naming) } label: {
                    Text("Give it a name")
                        .font(Theme.font(15, .black)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Capsule().fill(Theme.coral)
                            .shadow(color: Theme.coral.opacity(0.35), radius: 16, y: 6))
                }
                .buttonStyle(.plain)
                .padding(.top, 14)

                Button { state.endAdoption() } label: {
                    Text("Later").font(Theme.font(14, .heavy)).foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 34)
        }
        .background(Theme.paper.ignoresSafeArea())
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.26)
                          : .spring(response: 0.5, dampingFraction: 0.62)) { landed = true }
        }
    }

    private var arrivalLine: String {
        let n = state.owned.count
        let ordinal = ["first", "second", "third", "fourth", "fifth", "sixth"]
        let which = n <= ordinal.count ? ordinal[n - 1] : "\(n)th"
        return "Your \(which) kin. It's yours for good — nothing takes it back."
    }
}

/// Flat 45°-rotated squares, the same construction the Home celebration uses.
struct Confetti: View {
    let active: Bool
    private let bits: [(x: CGFloat, y: CGFloat, s: CGFloat, c: Color)] = [
        (-96, -30, 11, Theme.coin), (78, -46, 9, Theme.coral), (-58, -96, 13, Theme.mint),
        (104, 12, 8, Theme.lavender), (-118, 36, 10, Theme.pink), (44, -104, 12, Theme.coin),
    ]

    var body: some View {
        ZStack {
            ForEach(Array(bits.enumerated()), id: \.offset) { _, b in
                Rectangle()
                    .fill(b.c)
                    .frame(width: b.s, height: b.s)
                    .rotationEffect(.degrees(45))
                    .offset(x: b.x, y: active ? b.y - 34 : b.y)
                    .opacity(active ? 0 : 1)
                    .animation(.easeOut(duration: 0.9), value: active)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 3. Naming

/// Finch's flow, near enough verbatim, because it is already right. Two deliberate
/// changes: the commit button takes mint rather than coral, because naming is a
/// completion and not a spend; and the field arrives pre-filled from Shuffle, so
/// tapping straight through is a valid answer.
struct NameKinSheet: View {
    @EnvironmentObject var state: AppState
    let species: ChibiSpecies

    @FocusState private var focused: Bool

    private var draft: Binding<String> {
        Binding(get: { state.adoption?.draftName ?? "" },
                set: { new in
                    guard var flow = state.adoption else { return }
                    flow.draftName = String(new.prefix(14))
                    state.adoption = flow
                })
    }

    var body: some View {
        VStack(spacing: 14) {
            KinArtView(speciesID: species.id, expression: .delight, size: 150)
                .frame(height: 140)
                .padding(.top, 10)

            Text("What do you want to name your \(species.name.lowercased())?")
                .font(Theme.font(21, .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text("You can change this later.")
                .font(Theme.font(14.5, .bold)).foregroundStyle(Theme.muted)

            TextField("", text: draft)
                .font(Theme.font(19, .black))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit { commit() }
                .padding(.horizontal, 16)
                .frame(height: 58)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.hex(0xF7F3EA))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 2)))

            HStack(spacing: 10) {
                Button { state.shuffleDraftName() } label: {
                    HStack(spacing: 7) {
                        KinIcon(.die, size: 17, color: Theme.ink)
                        Text("Shuffle").font(Theme.font(15, .black)).foregroundStyle(Theme.ink)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Capsule().fill(Theme.card)
                        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 2)))
                }
                .buttonStyle(.plain)

                Button(action: commit) {
                    Text("Next").font(Theme.font(15, .black)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(Theme.mint)
                            .shadow(color: Theme.mint.opacity(0.34), radius: 14, y: 5))
                }
                .buttonStyle(.plain)
                .disabled(draft.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Text("This name replaces \u{201C}\(species.name)\u{201D} on Home, in Ask Kin and on the adoption card.")
                .font(Theme.font(11.5, .heavy))
                .foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24).padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Theme.paper)
    }

    private func commit() {
        focused = false
        state.commitName()
    }
}

// MARK: - 4. Certificate

struct CertificateSheet: View {
    @EnvironmentObject var state: AppState
    let species: ChibiSpecies

    var body: some View {
        VStack(spacing: 16) {
            if let kin = state.ownedKin(species.id) {
                AdoptionCard(species: species, kin: kin,
                             daysTogether: state.daysTogether(kin),
                             lifetime: state.game.stats(since: kin),
                             canvasFinished: state.game.canvasFinished(since: kin),
                             serial: state.owned.count)
            }
            Button { state.meetKin(species) } label: {
                Text("Meet \(state.ownedKin(species.id)?.displayName ?? species.name)")
                    .font(Theme.font(15, .black)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Capsule().fill(Theme.coral))
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 34)
        .background(Theme.hex(0xF1EADC))
    }
}

/// The keepsake, built to be screenshotted. The four together-since slots ship
/// **empty on purpose** — on day one the card is a promise, and on day two hundred
/// it is a record. None of them ever go down on their own.
struct AdoptionCard: View {
    let species: ChibiSpecies
    let kin: OwnedChibi
    let daysTogether: Int
    let lifetime: LifetimeStats
    let canvasFinished: Int?
    let serial: Int

    private static let dateStyle: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.tier(species.tier)).frame(height: 8)

            VStack(spacing: 10) {
                Text("CERTIFICATE OF ADOPTION")
                    .font(Theme.font(10, .black)).tracking(2)
                    .foregroundStyle(Theme.muted)

                KinArtView(speciesID: species.id, level: kin.level, skin: kin.skinID, size: 188)
                    .frame(height: 176)

                Text(kin.displayName)
                    .font(Theme.font(kin.displayName.count > 10 ? 24 : 32, .black))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    TierPlate(tier: species.tier, dense: true)
                    // The species line is what a name replaced. Under a kin still called
                    // "Ember" it only prints Ember twice, so it waits until they differ.
                    if kin.displayName.caseInsensitiveCompare(species.name) != .orderedSame {
                        Text(species.name).font(Theme.font(12.5, .bold)).foregroundStyle(Theme.muted)
                    }
                }

                StarPips(level: kin.level, size: 19, spacing: 6)

                Rectangle().fill(Theme.hex(0xEBE2D2)).frame(height: 1).padding(.vertical, 4)

                if let at = kin.adoptedAt {
                    Text("Adopted \(Self.dateStyle.string(from: at))")
                        .font(Theme.font(12.5, .bold)).foregroundStyle(Theme.muted)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    slot("\(daysTogether)",
                         daysTogether == 1 ? "day together" : "days together", filled: true)
                    slot(canvasFinished.map(String.init),
                         canvasFinished == 1 ? "assignment" : "assignments")
                    slot(lifetime.focusMinutes > 0 ? focusText : nil, "focused")
                    slot(lifetime.lessonsRead > 0 ? "\(lifetime.lessonsRead)" : nil,
                         lifetime.lessonsRead == 1 ? "lesson read" : "lessons read")
                }
                .padding(.top, 4)

                Text("These fill themselves in. None of them ever go down.")
                    .font(Theme.font(11, .heavy)).foregroundStyle(Theme.dim)
                    .multilineTextAlignment(.center)

                HStack(spacing: 6) {
                    Circle().fill(Theme.slime).frame(width: 9, height: 9)
                    Text("Prepkin Canvas").font(Theme.font(11, .black)).foregroundStyle(Theme.muted)
                    Spacer()
                    Text(String(format: "No. %03d", serial))
                        .font(Theme.font(11, .heavy)).foregroundStyle(Theme.dim)
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 16)
        }
        .background(Theme.hex(0xFDFBF6))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.hex(0xEBE2D2), lineWidth: 1.5)
                .padding(8)
        )
        .shadow(color: Theme.hex(0x2E2822).opacity(0.13), radius: 28, y: 8)
    }

    private var focusText: String {
        let h = lifetime.focusMinutes / 60, m = lifetime.focusMinutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private func slot(_ value: String?, _ label: String, filled: Bool = false) -> some View {
        VStack(spacing: 1) {
            Text(value ?? "—")
                .font(Theme.font(17, .black))
                .foregroundStyle(value == nil ? Theme.hex(0xDDD3C4) : Theme.ink)
            Text(label)
                .font(Theme.font(10, .heavy))
                .foregroundStyle(value == nil ? Theme.hex(0xDDD3C4) : Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }
}
