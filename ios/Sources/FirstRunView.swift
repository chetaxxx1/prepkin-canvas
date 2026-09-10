import SwiftUI

/// The first run, per `design_handoff_first_run/README.md`.
///
/// Two screens and out: name the kin, pick three tasks for today, then Home. The
/// only commitment is a name; the second screen is only tapping. Nothing is asked
/// for here — notifications and Canvas arrive later, as cards on Home, after the
/// first check-off.
struct FirstRunView: View {
    @EnvironmentObject var state: AppState

    private enum Screen { case name, pick }
    private typealias D = DayEditorView.D

    @State private var screen: Screen = .name
    @State private var name = ""
    @State private var shuffleIndex = -1
    @State private var picked: Set<String> = []
    @State private var hatched = false
    @FocusState private var typing: Bool

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            switch screen {
            case .name:
                nameScreen
                    .transition(.asymmetric(insertion: .move(edge: .leading),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
            case .pick:
                pickScreen
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
    }

    // MARK: - 1 · Hatch and name

    private var nameScreen: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Theme.tile)
                .frame(width: 180, height: 180)
                .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(Theme.tileRing, lineWidth: 1.5))
                .overlay(alignment: .bottom) {
                    SproutImage(speciesID: state.activeChibiID,
                                level: state.activeChibi.level,
                                skin: state.activeChibi.skinID,
                                size: 160)
                        .padding(.bottom, 8)
                }
                .scaleEffect(hatched ? 1 : 0.94)
                .offset(y: hatched ? 0 : 18)
                .opacity(hatched ? 1 : 0)
                .onAppear { withAnimation(.easeOut(duration: 0.6)) { hatched = true } }

            Text("What do you want to name your kin?")
                .font(Theme.font(26, .black))
                .kerning(-0.5)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 28)

            Text("You can change this later.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .padding(.top, 8)

            ZStack {
                if name.isEmpty {
                    Text("Name")
                        .font(Theme.font(20, .heavy))
                        .foregroundStyle(D.placeholder)
                }
                TextField("", text: $name)
                    .accessibilityLabel("Your kin's name")
                    .font(Theme.font(20, .heavy))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .focused($typing)
                    .submitLabel(.next)
                    .onSubmit { if canGoNext { next() } }
                    .onChange(of: name) { _, new in
                        // `GameState.rename` caps at 14; the field should not let
                        // the student type a fifteenth letter that then vanishes.
                        if new.count > 14 { name = String(new.prefix(14)) }
                    }
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.card)
                .shadow(color: D.cardShadow, radius: 11, y: 8))
            .padding(.top, 24)

            HStack(spacing: 10) {
                Button(action: shuffle) {
                    HStack(spacing: 8) {
                        KinIcon(.die, size: 18, color: Theme.coral)
                        Text("Shuffle")
                            .font(Theme.font(17, .bold))
                            .foregroundStyle(Theme.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(D.field))
                }
                .buttonStyle(.plain)

                Button(action: next) {
                    Text("Next")
                        .font(Theme.font(17, .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Theme.coral))
                        .opacity(canGoNext ? 1 : 0.4)
                        .shadow(color: Theme.coral.opacity(canGoNext ? 0.3 : 0), radius: 10, y: 8)
                }
                .buttonStyle(.plain)
                .disabled(!canGoNext)
            }
            .padding(.top, 12)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .padding(.top, 99)
        .ignoresSafeArea(edges: .top)
        .animation(.easeInOut(duration: 0.18), value: canGoNext)
    }

    private var canGoNext: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The next name down the list, not a random one, so tapping again never
    /// hands back the name just rejected.
    private func shuffle() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        shuffleIndex = (shuffleIndex + 1) % GameState.shuffleNames.count
        name = GameState.shuffleNames[shuffleIndex]
    }

    private func next() {
        guard canGoNext else { return }
        typing = false
        state.rename(state.activeChibiID, to: name)
        screen = .pick
    }

    // MARK: - 2 · Pick three for today

    private var presets: [TaskTemplate] { state.templates.filter(\.isPreset) }
    private var coinsToday: Int {
        presets.filter { picked.contains($0.id) }.reduce(0) { $0 + $1.kind.reward }
    }
    private var canContinue: Bool { picked.count == 3 }

    private var pickScreen: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Pinned, like the prototype's fixed header and like HomeView: the
                // counter and the progress bar are the feedback for the tapping, so
                // they cannot scroll away while the student taps. It also keeps the
                // rows from sliding up under the clock and the island.
                VStack(spacing: 0) {
                    Text("Pick three for today")
                        .font(Theme.font(34, .black))
                        .kerning(-0.9)
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    kinCard.padding(.top, 16)
                }
                .padding(.horizontal, 22)
                .padding(.top, 99)

                ScrollView {
                    VStack(spacing: 0) {
                        eyebrow("STUDY IDEAS")
                        rows(presets.filter { $0.kind == .study })
                        eyebrow("LIFE CARE").padding(.top, 14)
                        rows(presets.filter { $0.kind == .life })
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 22)
                    .padding(.bottom, 140)
                }
                .scrollIndicators(.hidden)
            }
            .ignoresSafeArea(edges: .top)

            continueButton
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var continueButton: some View {
        Button(action: finish) {
            Text("Continue")
                .font(Theme.font(17, .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Theme.coral))
                .opacity(canContinue ? 1 : 0.4)
                .shadow(color: Theme.coral.opacity(canContinue ? 0.3 : 0), radius: 10, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!canContinue)
        .padding(.horizontal, 22)
        .padding(.top, 40)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(stops: [.init(color: Theme.paper.opacity(0), location: 0),
                                   .init(color: Theme.paper, location: 0.3),
                                   .init(color: Theme.paper, location: 1)],
                           startPoint: .top, endPoint: .bottom)
        )
        .ignoresSafeArea(edges: .bottom)
        .animation(.easeInOut(duration: 0.18), value: canContinue)
    }

    private func finish() {
        guard canContinue else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            state.finishFirstRun(picked: picked)
        }
    }

    // MARK: Kin card (DayEditorView.kinCard, with this screen's strings)

    private var kinCard: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.paper)
                .frame(width: 92, height: 92)
                .overlay(
                    SproutImage(speciesID: state.activeChibiID,
                                level: state.activeChibi.level,
                                skin: state.activeChibi.skinID,
                                size: 84)
                        .padding(.bottom, 6)
                )
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Text(picked.isEmpty ? "Nothing picked yet" : "\(picked.count) of 3 picked")
                        .font(Theme.font(17, .bold))
                        .kerning(-0.2)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        // A Spacer here made three children, so the row paid the 10pt
                        // spacing twice and left the label 103.25pt for 147.8pt of
                        // glyphs — scale .699, a hair under the old .7 floor, so it
                        // stopped scaling and truncated to "Nothing picked...".
                        // Taking the slack directly gives that gap back; .55 keeps
                        // narrower phones off the same cliff.
                        .minimumScaleFactor(0.55)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    coinChip("\(coinsToday) today").fixedSize()
                }
                Text("Tap what fits. \(state.activeChibi.displayName) keeps you company.")
                    .font(Theme.font(15, .semibold))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
                    .padding(.top, 4)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hairline)
                        Capsule().fill(Theme.mint)
                            .frame(width: geo.size.width * CGFloat(picked.count) / 3)
                    }
                }
                .frame(height: 10)
                .padding(.top, 12)
                .animation(.easeInOut(duration: 0.3), value: picked.count)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Theme.card)
            .shadow(color: D.cardShadow, radius: 11, y: 8))
    }

    private func coinChip(_ text: String) -> some View {
        HStack(spacing: 5) {
            CoinDisc(size: 14)
            Text(text)
                .font(Theme.font(14, .bold))
                .foregroundStyle(D.goldInk)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(D.goldTint))
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(12, .bold))
            .kerning(1.5)
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .padding(.bottom, 10)
    }

    // MARK: Rows (DayEditorView.row, coin line only, check disc instead of toggle)

    private func rows(_ templates: [TaskTemplate]) -> some View {
        VStack(spacing: 10) {
            ForEach(templates) { t in row(t) }
        }
    }

    private func row(_ t: TaskTemplate) -> some View {
        let on = picked.contains(t.id)
        return HStack(spacing: 14) {
            IconTile(icon: DayEditorView.category(t).rawValue, size: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(t.title)
                    .font(Theme.font(17, .bold))
                    .kerning(-0.2)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                HStack(spacing: 5) {
                    CoinDisc(size: 12.5)
                    Text("+\(t.kind.reward) coins")
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(D.goldInk)
                }
            }
            Spacer(minLength: 0)
            checkDisc(on: on)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.card)
                .shadow(color: on ? Theme.mint.opacity(0.14) : D.cardShadow, radius: 11, y: 8)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(on ? Theme.mint : .clear, lineWidth: 2.5))
        )
        .contentShape(Rectangle())
        .onTapGesture { toggle(t.id) }
        .animation(.easeInOut(duration: 0.18), value: on)
        // One element per row, read as a button: VoiceOver otherwise hears four
        // loose labels and nothing it can pick.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(t.title), \(t.kind.reward) coins")
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    private func checkDisc(on: Bool) -> some View {
        Circle()
            .fill(on ? Theme.mint : Theme.checkFill)
            .overlay {
                if on {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                } else {
                    Circle().strokeBorder(Theme.checkBorder, lineWidth: 2.5)
                }
            }
            .frame(width: 30, height: 30)
    }

    /// Cap at three: a fourth tap does nothing, no shake, no message.
    private func toggle(_ id: String) {
        if picked.contains(id) {
            picked.remove(id)
        } else {
            guard picked.count < 3 else { return }
            picked.insert(id)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
