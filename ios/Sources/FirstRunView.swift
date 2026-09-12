import SwiftUI

/// The first run, per `design/ONBOARDING-PROMPT.md`.
///
/// Seven screens: welcome, where in school, what's on your plate, pick a coat,
/// name, pick three, your day is set — then Home. Every question changes a screen
/// after it (`FirstRun.swift` says which), the two questions can be skipped, the
/// coat and the name cannot, and the step is saved as it moves so a killed app
/// comes back to the same screen. Nothing here asks for an account, a school
/// name, or a permission. Each screen names the Mobbin screen it copies.
struct FirstRunView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private typealias D = DayEditorView.D

    @State private var step: FirstRunStep = .welcome
    /// Which way the last move went, so the screens slide the way the thumb did.
    @State private var forward = true
    @State private var school: SchoolLevel?
    @State private var plate: [PlateItem] = []
    @State private var coat: StarterCoat?
    @State private var name = ""
    @State private var shuffleIndex = -1
    @State private var picked: Set<String> = []
    @State private var showOtherPhone = false
    @State private var friendNote = false
    /// The reveal: the fish swims in, waves, and the name field rises.
    @State private var swamIn = false
    @State private var waved = 0
    @State private var fieldUp = false
    /// The real text field joins a beat after the rise. Its first appearance
    /// brings up the keyboard machinery on the main thread, which on a slow
    /// simulator held the whole rise back until it was done.
    @State private var fieldLive = false
    @FocusState private var typing: Bool

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Group {
                    switch step {
                    case .welcome: welcomeScreen
                    case .school: schoolScreen
                    case .plate: plateScreen
                    case .coat: coatScreen
                    case .name: nameScreen
                    case .picks: pickScreen
                    case .result: resultScreen
                    }
                }
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
        .sheet(isPresented: $showOtherPhone) { otherPhoneSheet }
        .onAppear(perform: resume)
    }

    // MARK: - Moving

    /// Picks up where a killed app left off. The answers already given are
    /// read back off the save so Back still shows them ticked.
    private func resume() {
        step = state.firstRunStep
        school = state.schoolLevel
        plate = state.plate
        coat = state.pickedCoat.flatMap(StarterCoat.init(rawValue:))
        if let saved = state.activeChibi.name { name = saved }
        picked = Set(state.presetMenu().filter(\.isActive).map(\.id))
        if step == .picks, picked.count != 3 { picked = suggested }
        if step == .name { swamIn = true; fieldUp = true; fieldLive = true }
    }

    private func go(to next: FirstRunStep) {
        forward = next > step
        typing = false
        step = next
        state.setFirstRunStep(next)
    }

    private func back() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch step {
        case .welcome: break
        case .school: go(to: .welcome)
        case .plate: go(to: .school)
        case .coat: go(to: .plate)
        case .name: go(to: .coat)
        case .picks: go(to: .name)
        case .result: go(to: .picks)
        }
    }

    // MARK: - Top bar: Back, the thin bar (Duolingo's), Skip
    //
    // Duolingo's question shell, https://mobbin.com/screens/6f28eb68-b3c3-43d1-a4be-fb5f43b8f930:
    // a chevron, a thin bar that fills across the questions, and nothing else.

    private var topBar: some View {
        HStack(spacing: 12) {
            if step != .welcome {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
            if let progress = step.progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hairline)
                        Capsule().fill(Theme.mint)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 8)
                .animation(.easeInOut(duration: 0.3), value: progress)
                .accessibilityHidden(true)
            } else {
                Spacer()
            }
            if step == .school || step == .plate {
                Button { skip() } label: {
                    Text("Skip")
                        .font(Theme.font(15, .bold))
                        .foregroundStyle(Theme.muted)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    /// A skipped question stores nothing, and the app runs as college.
    private func skip() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch step {
        case .school: school = nil; state.answerSchool(nil); go(to: .plate)
        case .plate: plate = []; state.answerPlate([]); go(to: .coat)
        default: break
        }
    }

    // MARK: - 1 · Welcome
    //
    // Finch's welcome, https://mobbin.com/screens/d57f16e6-eb3b-4562-810c-0c6be6eaf239:
    // the bird, one line, one button, the invite link and the legal line under
    // it. Saturn's one-line pitch, https://mobbin.com/screens/9efc1ae1-bd4f-4332-b473-082e0f67a929.

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            tankCard(height: 300) {
                SproutImage(speciesID: state.activeChibiID, level: 1, size: 170)
            }
            .padding(.top, 8)

            Text("Your Canvas, a fish, and coins for finishing.")
                .font(Theme.font(27, .black))
                .kerning(-0.6)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, 28)

            Spacer(minLength: 12)

            primaryButton("Meet your fish", enabled: true) { go(to: .school) }
                .accessibilityIdentifier("meet-your-fish")

            quietButton("Have a friend code?") {
                state.openAddFriendRequest = true
                withAnimation(.easeOut(duration: 0.2)) { friendNote = true }
            }
            .padding(.top, 6)
            if friendNote {
                Text("Add them after setup. Two minutes.")
                    .font(Theme.font(13.5, .bold))
                    .foregroundStyle(Theme.mintDark)
                    .transition(.opacity)
            }
            quietButton("Already use Prepkin on another phone?") { showOtherPhone = true }

            legalLine.padding(.top, 10)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
    }

    /// Finch's "By continuing, you agree to…", as two short lines with the
    /// links in them. Both pages exist on prepkin.com.
    private var legalLine: some View {
        VStack(spacing: 2) {
            Text("By continuing you accept the")
            HStack(spacing: 4) {
                Link(destination: URL(string: "https://prepkin.com/terms")!) { Text("Terms").underline() }
                Text("and")
                Link(destination: URL(string: "https://prepkin.com/privacy")!) { Text("Privacy Policy").underline() }
            }
        }
        .font(Theme.font(12, .bold))
        .foregroundStyle(Theme.dim)
        .tint(Theme.dim)
    }

    /// No accounts, said plainly. The laptop link is how work follows you.
    private var otherPhoneSheet: some View {
        VStack(spacing: 14) {
            SproutImage(speciesID: state.activeChibiID, level: 1, size: 110)
                .padding(.top, 26)
            Text("No accounts here.")
                .font(Theme.font(24, .black))
                .foregroundStyle(Theme.ink)
            VStack(spacing: 6) {
                Text("Your fish and coins stay on this phone.")
                Text("Canvas work follows your laptop link.")
                Text("Pair Chrome with this phone's code.")
            }
            .font(Theme.font(15, .semibold))
            .foregroundStyle(Theme.muted)
            .multilineTextAlignment(.center)
            Spacer(minLength: 8)
            primaryButton("Got it", enabled: true) { showOtherPhone = false }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.paper)
    }

    // MARK: - 2 · Where are you in school?
    //
    // Duolingo Math's "Grades 2 through 12 / University / I'm an adult learner",
    // https://mobbin.com/screens/ce101753-63a5-4c96-bf23-33f584d0a4ba, asked from
    // the bubble. Saturn asks for a school name and a year and is the anti-reference.

    private var schoolScreen: some View {
        VStack(spacing: 0) {
            askRow("Where are you in school?")
            VStack(spacing: 10) {
                ForEach(SchoolLevel.allCases) { level in
                    choiceRow(level.label, on: school == level) {
                        school = level
                        state.answerSchool(level)
                    }
                }
            }
            .padding(.top, 22)
            Spacer(minLength: 12)
            primaryButton("Continue", enabled: school != nil) { go(to: .plate) }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
    }

    // MARK: - 3 · What's on your plate?
    //
    // Headspace's multi-select goals, https://mobbin.com/screens/6aba84cc-e359-446c-8cf3-b10cae809456,
    // and Duolingo's multi-select under the bubble, https://mobbin.com/screens/1a2c3854-ea7a-41fa-ab1b-95466c2c0228.

    private var plateScreen: some View {
        VStack(spacing: 0) {
            askRow("What's on your plate?")
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(PlateItem.allCases) { item in
                        choiceRow(item.label, on: plate.contains(item), multi: true) {
                            if let i = plate.firstIndex(of: item) { plate.remove(at: i) } else { plate.append(item) }
                            state.answerPlate(plate)
                        }
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            primaryButton("Continue", enabled: !plate.isEmpty) { go(to: .coat) }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
    }

    /// The fish asks from a bubble, Duolingo's shape.
    private func askRow(_ question: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            SproutImage(speciesID: state.activeChibiID, level: 1, size: 130)
            Text(question)
                .font(Theme.font(20, .black))
                .kerning(-0.3)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.card)
                        .shadow(color: D.cardShadow, radius: 11, y: 8))
                .overlay(alignment: .leading) {
                    // The bubble's tail, pointing at him.
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: 0))
                        p.addLine(to: CGPoint(x: -10, y: 8))
                        p.addLine(to: CGPoint(x: 0, y: 16))
                        p.closeSubpath()
                    }
                    .fill(Theme.card)
                    .frame(width: 10, height: 16)
                    .offset(x: -0.5, y: 0)
                }
            Spacer(minLength: 0)
        }
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
    }

    private func choiceRow(_ label: String, on: Bool, multi: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 14) {
                Text(label)
                    .font(Theme.font(17, .bold))
                    .kerning(-0.2)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                checkDisc(on: on)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 18)
            .frame(minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: on ? Theme.mint.opacity(0.14) : D.cardShadow, radius: 11, y: 8)
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(on ? Theme.mint : .clear, lineWidth: 2.5)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: on)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: - 4 · Pick your coat
    //
    // Finch's egg pick, https://mobbin.com/screens/9a45c4b2-8ef7-4b6b-af4f-434673afd0c0:
    // the choices in a ring, one ringed, one button. A coat is a colour of the
    // one fish, so Sprout is still the only species on screen.

    private var coatScreen: some View {
        VStack(spacing: 0) {
            Text("Pick your coat")
                .font(Theme.font(30, .black))
                .kerning(-0.7)
                .foregroundStyle(Theme.ink)
                .padding(.top, 6)
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Theme.tile)
                    .overlay(
                        Image(Scene0.all[0].asset)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(Theme.tileRing, lineWidth: 1.5))
                let cols = [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)]
                LazyVGrid(columns: cols, spacing: 18) {
                    ForEach(StarterCoat.allCases) { c in coatTile(c) }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .padding(.top, 18)
            Spacer(minLength: 12)
            Text("A coat is a colour. Each one is Sprout.")
                .font(Theme.font(15, .semibold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: 12)
            primaryButton("Meet", enabled: coat != nil) {
                guard let coat else { return }
                state.pickCoat(coat)
                swamIn = false; fieldUp = false; fieldLive = false; waved = 0
                go(to: .name)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
    }

    private func coatTile(_ c: StarterCoat) -> some View {
        let on = coat == c
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            coat = c
        } label: {
            Circle()
                .fill(Theme.card.opacity(on ? 1 : 0.82))
                .overlay(Circle().strokeBorder(on ? Theme.coral : Theme.tileRing, lineWidth: on ? 3 : 1.5))
                // The still is a square box with the one-star fish on its floor, so
                // the picture is lifted to put the fish, not the box, in the middle.
                .overlay(
                    Image("sprout-\(c.rawValue)-1")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .offset(y: -34))
                .clipShape(Circle())
                .scaleEffect(on ? 1.06 : 1)
                .shadow(color: on ? Theme.coral.opacity(0.25) : D.cardShadow, radius: 12, y: 8)
                .frame(height: 148)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: on)
        .accessibilityLabel("\(c.rawValue.capitalized) coat")
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: - 5 · The reveal, then the name
    //
    // Finch's hatch beat, https://mobbin.com/screens/e35e65d4-5375-4ea1-99f1-b83e54d88140 and
    // https://mobbin.com/screens/597d5b39-b912-43a6-8b6c-8e6045260727, then Finch's
    // name screen, https://mobbin.com/screens/0b3973cb-4909-47e5-a90f-aa289957b6d4.
    // The one animation in the flow: the fish swims in from the left, waves, and
    // the name field rises. Needs George's GIF sign-off before it ships.

    private var nameScreen: some View {
        VStack(spacing: 0) {
            tankCard(height: 220) {
                SproutImage(speciesID: state.activeChibiID, level: 1,
                            animation: .wave, replay: waved, size: 150)
                    .offset(x: swamIn ? 0 : -260, y: swamIn ? 0 : 6)
                    .rotationEffect(.degrees(swamIn ? 0 : -6), anchor: .bottom)
            }
            .padding(.top, 8)
            .task { await reveal() }

            Group {
                Text("What do you want to name your kin?")
                    .font(Theme.font(26, .black))
                    .kerning(-0.5)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 26)

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
                    if fieldLive {
                        TextField("", text: $name)
                            .accessibilityLabel("Your kin's name")
                            .font(Theme.font(20, .heavy))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .focused($typing)
                            .submitLabel(.next)
                            .onSubmit { if canGoNext { nextFromName() } }
                            .onChange(of: name) { _, new in
                                // `GameState.rename` caps at 14; the field should not let
                                // the student type a fifteenth letter that then vanishes.
                                if new.count > 14 { name = String(new.prefix(14)) }
                            }
                    }
                }
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: D.cardShadow, radius: 11, y: 8))
                .padding(.top, 22)

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

                    primaryButton("Next", enabled: canGoNext, action: nextFromName)
                }
                .padding(.top, 12)
            }
            .opacity(fieldUp ? 1 : 0)
            .offset(y: fieldUp ? 0 : 24)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.18), value: canGoNext)
    }

    /// Swim in (0.9s), wave, then the field rises. Reduce Motion skips straight
    /// to the end state. Runs from `.task`, so every write lands on the main
    /// actor inside a SwiftUI transaction: an unstructured `Task` from
    /// `onAppear` wrote the flags off the main thread and the screen did not
    /// redraw until something else on Home did.
    @MainActor
    private func reveal() async {
        guard !swamIn else { return }
        if reduceMotion {
            swamIn = true; fieldUp = true; fieldLive = true
            return
        }
        withAnimation(.easeOut(duration: 0.9)) { swamIn = true }
        try? await Task.sleep(for: .seconds(0.95))
        guard !Task.isCancelled else { return }
        waved += 1
        try? await Task.sleep(for: .seconds(0.7))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.45)) { fieldUp = true }
        try? await Task.sleep(for: .seconds(0.5))
        fieldLive = true
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

    private func nextFromName() {
        guard canGoNext else { return }
        state.rename(state.activeChibiID, to: name)
        picked = suggested
        go(to: .picks)
    }

    // MARK: - 6 · Pick three for today
    //
    // Finch's first-goals screen, https://mobbin.com/screens/75c0006a-8e29-4db7-bbc6-7bcf3d6c7655.
    // Three arrive ticked (`FirstRun.suggestedPicks`, from the two answers), so
    // Continue is live on arrival and the student only swaps.

    /// Strictly the level's list: the catalogue's own defaults (active before
    /// any pick was made) must not leak a college row onto a high-schooler's screen.
    private var presets: [TaskTemplate] {
        let ids = Set(state.school.presetIDs)
        return state.presetMenu().filter { ids.contains($0.id) }
    }
    private var suggested: Set<String> {
        Set(FirstRun.suggestedPicks(school: state.school, plate: plate, presets: presets))
    }
    private var coinsToday: Int {
        presets.filter { picked.contains($0.id) }.reduce(0) { $0 + $1.kind.reward }
    }
    private var canContinue: Bool { picked.count == 3 }

    private var pickScreen: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Pinned, like HomeView: the counter and the bar are the feedback
                // for the tapping, so they cannot scroll away while the student taps.
                VStack(spacing: 0) {
                    Text("Pick three for today")
                        .font(Theme.font(34, .black))
                        .kerning(-0.9)
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    kinCard.padding(.top, 16)
                }
                .padding(.horizontal, 22)
                .padding(.top, 6)

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

            continueButton
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var continueButton: some View {
        primaryButton("Continue", enabled: canContinue) {
            guard canContinue else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            state.applyPicks(picked)
            go(to: .result)
        }
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
    }

    // MARK: - 7 · Your day is set
    //
    // Headspace's "Your style is…" result, https://mobbin.com/screens/71a1f085-c0df-44b4-9675-7cbe8b429094,
    // and its plan screen, https://mobbin.com/screens/3ab1a91f-775e-4f76-9610-f6ca895349e7.
    // What the answers unlocked, on one screen: the fish, the three picks with
    // their coins, one line. No plan length, no dates, no meter.

    private var resultScreen: some View {
        let chosen = presets.filter(\.isActive)
        let kinName = state.activeChibi.displayName
        return VStack(spacing: 0) {
            SproutImage(speciesID: state.activeChibiID, level: 1, size: 150)
                .padding(.top, 4)
            Text("Your day is set.")
                .font(Theme.font(30, .black))
                .kerning(-0.7)
                .foregroundStyle(Theme.ink)
                .padding(.top, 8)
            VStack(spacing: 10) {
                ForEach(chosen) { t in
                    HStack(spacing: 14) {
                        IconTile(icon: DayEditorView.category(t).rawValue, size: 44)
                        Text(t.title)
                            .font(Theme.font(17, .bold))
                            .kerning(-0.2)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                        coinChip("+\(t.kind.reward)")
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Theme.card)
                        .shadow(color: D.cardShadow, radius: 11, y: 8))
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, 22)
            VStack(spacing: 4) {
                Text("Finish one. \(kinName) gets paid.")
                Text("That's the whole thing.")
            }
            .font(Theme.font(16, .bold))
            .foregroundStyle(Theme.muted)
            .multilineTextAlignment(.center)
            .padding(.top, 22)
            Spacer(minLength: 12)
            primaryButton("Let's go", enabled: true) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.easeInOut(duration: 0.3)) { state.finishFirstRun() }
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
    }

    // MARK: - Pieces

    /// The lagoon in a rounded tile, with the fish on its floor. Every screen
    /// from the coat on has him; the welcome has him too, so the first thing on
    /// screen is the fish and not a text field.
    private func tankCard<Fish: View>(height: CGFloat, @ViewBuilder fish: () -> Fish) -> some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(Theme.tile)
            .overlay(Image(Scene0.all[0].asset).resizable().scaledToFill())
            .overlay(alignment: .bottom) { fish().padding(.bottom, 14) }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(Theme.tileRing, lineWidth: 1.5))
            .frame(maxWidth: .infinity)
            .frame(height: height)
    }

    private func primaryButton(_ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.font(17, .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Theme.coral))
                .opacity(enabled ? 1 : 0.4)
                .shadow(color: Theme.coral.opacity(enabled ? 0.3 : 0), radius: 10, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.18), value: enabled)
    }

    private func quietButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.font(15, .bold))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                Text("Swap any. \(state.activeChibi.displayName) keeps you company.")
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
