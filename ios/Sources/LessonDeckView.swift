import SwiftUI

/// The reader. One idea per card, one figure that grows across the deck.
///
/// Three rules from the handoff that are easy to break by accident:
/// - **Leaving is silent.** No confirm dialog, no guilt copy. The place is kept.
/// - **The check card pays nothing.** Coins are for finishing, never for correctness,
///   and the card says so out loud so the student doesn't wonder.
/// - **Body copy is left aligned.** The old reader centred a paragraph; a centred
///   ragged-left block is slower to read and looked like a pull quote.
struct LessonDeckView: View {
    let lesson: Lesson
    /// Called when the student takes the one forward move on the complete screen.
    /// The presenter swaps the deck rather than stacking a second reader on top.
    var onNext: (Lesson) -> Void = { _ in }

    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var index: Int
    /// Which choice was tapped on each check card. Present means locked.
    @State private var answers: [Int: Int] = [:]
    @State private var showCoach = false
    @State private var askKin = false
    /// The flag sheet, and which reason is picked inside it. The reason is cleared
    /// with the sheet, so the next card starts blank.
    @State private var reporting = false
    @State private var reportReason: CardReportReason?
    @State private var finished = false
    @State private var paid = 0
    @State private var finishing = false
    @State private var keyCheers = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// One 0→1 value per flying coin, so they can be staggered.
    @State private var arc: [Double] = Array(repeating: 0, count: 5)
    @State private var flying = false
    @State private var heartPop = false

    init(lesson: Lesson, startAt: Int = 0, onNext: @escaping (Lesson) -> Void = { _ in }) {
        self.lesson = lesson
        self.onNext = onNext
        _index = State(initialValue: min(max(startAt, 0), max(lesson.cards.count - 1, 0)))
    }

    private var cards: [LessonCard] { lesson.cards }
    private var isFinish: Bool { index >= cards.count }
    private var card: LessonCard? { isFinish ? nil : cards[index] }

    /// The deck's last card is a quick check, so stepping past it *is* finishing.
    /// The button waits for the answer: offered before one is locked it would be a
    /// way past the single question that makes the lesson stick.
    private var showsFinish: Bool {
        guard let card, index == cards.count - 1 else { return false }
        return card.kind != .check || answers[index] != nil
    }

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            if finished {
                LessonCompleteView(lesson: lesson, paid: paid, onNext: onNext) { dismiss() }
                    .transition(.opacity)
            } else {
                deck
            }
        }
        .animation(.easeOut(duration: 0.22), value: finished)
        .onAppear { showCoach = !state.hasSeenTapCoach }
        .sheet(isPresented: $askKin) { askKinSheet }
        .sheet(isPresented: $reporting, onDismiss: { reportReason = nil }) { reportSheet }
        // Clears the 52pt bottom bar rather than sitting on top of the heart.
        .kinToast(state.toast, bottom: 68)
    }

    // MARK: - Deck

    private var deck: some View {
        VStack(spacing: 0) {
            topBar
            GeometryReader { geo in
                content(in: geo.size)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .opacity(showCoach ? 0.2 : 1)
                    // Only the quick check has anything to press. On every other
                    // card the figure and the copy used to swallow the tap, so
                    // "tap here to go forward" only worked on the blank strip
                    // under the sentence.
                    .allowsHitTesting(card?.kind == .check)
                    // The zones sit *behind* the content, so on the check card an
                    // answer row still wins the tap and the space around it advances.
                    .background(alignment: .leading) { tapZones }
            }
            if showsFinish { finishButton }
            if !isFinish {
                bottomBar
                    // The coach owns the screen while it is up. Dimming the bar the same
                    // amount as the card stops the bar glowing through a 70% scrim, and
                    // nothing behind the coach can be pressed by accident.
                    .opacity(showCoach ? 0.2 : 1)
                    .allowsHitTesting(!showCoach)
            }
        }
        .overlay { if showCoach { coachOverlay } }
        .overlay(alignment: .topTrailing) { coinArc }
        .animation(.easeOut(duration: 0.2), value: showsFinish)
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.card))
            }
            .accessibilityLabel("Close")

            HStack(spacing: 4) {
                ForEach(0..<max(cards.count, 1), id: \.self) { i in
                    Capsule()
                        .fill(i < filledSegments ? Theme.mint : Theme.hex(0xEFE7D9))
                        .frame(height: 5)
                }
            }
            .animation(.easeOut(duration: 0.22), value: filledSegments)
            .accessibilityElement()
            .accessibilityLabel("Card \(min(index + 1, cards.count)) of \(cards.count)")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var filledSegments: Int { isFinish ? cards.count : index + 1 }

    /// Left third goes back, the rest goes forward. Faster than swiping and it keeps
    /// one thumb on the screen — but a swipe still works, for anyone who expects it.
    private var tapZones: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 130).contentShape(Rectangle()).onTapGesture { back() }
            Color.clear.contentShape(Rectangle()).onTapGesture { advance() }
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { g in g.translation.width < 0 ? advance() : back() }
        )
    }

    @ViewBuilder
    private func content(in size: CGSize) -> some View {
        if let card {
            switch card.kind {
            case .figure:  figureCard(card, in: size)
            case .image:   imageCard(card, in: size)
            case .text:    textCard(card)
            case .key:     keyCard(card)
            case .example: exampleCard(card, in: size)
            case .check:   checkCard(card)
            }
        } else {
            // The coins are already flying; the complete view takes over in a beat.
            Color.clear
        }
    }

    // MARK: - Card kinds

    /// The figure is a **band that bleeds to both edges**, not a card floating on the
    /// page. That is what makes it read as the lesson rather than as an illustration
    /// attached to it — and it is how the reference app frames every drawing.
    private func figureCard(_ card: LessonCard, in size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            GeometryReader { geo in
                LessonFigure(id: lesson.figure, step: card.step ?? 1)
                    .frame(width: geo.size.width,
                           height: min(geo.size.width / FigureSpace.aspect, size.height * 0.62))
                    .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30,
                                                      bottomTrailingRadius: 30,
                                                      style: .continuous))
            }
            .frame(height: min(size.width / FigureSpace.aspect, size.height * 0.62))

            bodyCopy(card.body)
            Spacer(minLength: 0)
        }
    }

    /// A painted card: the picture bleeds to both edges at 4:3, the way the figure band
    /// does, then the eyebrow and the copy. The picture is the lesson; the words are the
    /// caption. Every count in every picture was checked before it went in the catalogue
    /// — see the lesson-art notes — so nothing here crops or scales it: `scaledToFill` at
    /// the card's own 4:3 shows the whole thing.
    private func imageCard(_ card: LessonCard, in size: CGSize) -> some View {
        let h = min(size.width * 0.75, size.height * 0.56)
        return VStack(alignment: .leading, spacing: 0) {
            Image(card.image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: h)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30,
                                                  bottomTrailingRadius: 30,
                                                  style: .continuous))
            if !card.eyebrow.isEmpty {
                CardTypeLabel(card.eyebrow.uppercased())
                    .padding(.leading, 24).padding(.top, 22)
            }
            bodyCopy(card.body)
                .padding(.top, card.eyebrow.isEmpty ? 22 : 10)
            Spacer(minLength: 0)
        }
    }

    /// A lesson with no figure authored yet.
    ///
    /// Copy sits in a white card, top-anchored, the same surface a figure gets. Bare
    /// text floating on the page left a gap above *and* below and read as a screen
    /// that had failed to load; on a card the space below it is margin.
    private func textCard(_ card: LessonCard) -> some View {
        prosePanel(card.body, label: nil)
    }

    /// The card people screenshot. No figure, real air around the sentence, and the
    /// slime cropped by the screen edge so a shared screenshot carries the character.
    private func keyCard(_ card: LessonCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            keyArtifact(card)
                .padding(.horizontal, 20)

            HStack(alignment: .bottom, spacing: 10) {
                slime(size: 96, animation: .celebrate, expression: .delight, replay: keyCheers)
                Text("Screenshot this one.")
                    .font(Theme.font(13.5, .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 13).padding(.vertical, 9)
                    .background(UnevenRoundedRectangle(topLeadingRadius: 18,
                                                       bottomLeadingRadius: 6,
                                                       bottomTrailingRadius: 18,
                                                       topTrailingRadius: 18,
                                                       style: .continuous)
                        .fill(Theme.card)
                        .shadow(color: Theme.ink.opacity(0.06), radius: 6, y: 2))
                    .offset(y: -26)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)

            Spacer(minLength: 0)
        }
        // He is pleased with you for as long as you sit here, not for one second of it.
        .onReceive(Timer.publish(every: 2.6, on: .main, in: .common).autoconnect()) { _ in
            guard !reduceMotion else { return }
            keyCheers += 1
        }
    }

    /// The one card the app asks you to screenshot, so it is built to survive leaving
    /// the app: the picture you just assembled, the sentence, and what it came from.
    /// Before this it was a label, a pale panel and 600pt of empty screen.
    private func keyArtifact(_ card: LessonCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if LessonFigure.exists(lesson.figure) {
                LessonFigure(id: lesson.figure, step: LessonFigure.coverStep(lesson.figure))
                    .frame(height: 132)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("KEY IDEA")
                    .font(Theme.fixedFont(11, .heavy))
                    .tracking(1.3)
                    .foregroundStyle(TrackTint.ink(lesson.trackID))

                Text(card.body)
                    .font(Theme.font(22, .heavy))
                    .lineSpacing(22 * 0.36)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                HStack(spacing: 7) {
                    Rectangle().fill(TrackTint.accent(lesson.trackID))
                        .frame(width: 18, height: 2.5)
                    Text(lesson.title)
                        .font(Theme.font(12.5, .heavy))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                }
                .padding(.top, 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 20).padding(.bottom, 22)
        }
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Theme.card))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
            .strokeBorder(Theme.cardEdge, lineWidth: 1))
        .shadow(color: Theme.ink.opacity(0.07), radius: 16, y: 6)
    }

    private func exampleCard(_ card: LessonCard, in size: CGSize) -> some View {
        prosePanel(card.body, label: "FOR EXAMPLE")
    }

    /// Copy on its own white card. The one surface every figure-less card shares.
    private func prosePanel(_ text: String, label: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 14) {
                if let label { CardTypeLabel(label) }
                Text(text)
                    .font(Theme.font(21, .bold))
                    .lineSpacing(21 * 0.5)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 30).padding(.bottom, 34)
            // Tall enough to hold the middle of the screen. A panel sized only to its
            // copy floated in the page and read as something that failed to load.
            .frame(maxWidth: .infinity, minHeight: 296, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.card))
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
            Spacer(minLength: 0)
        }
        .padding(.top, 20)
    }

    /// One recall question. A wrong pick is never marked wrong — the row you tapped
    /// keeps a quiet label, the right answer turns mint, and the reason appears.
    ///
    /// Deliberately not scrollable: a scroll view would swallow the forward tap. Check
    /// cards are authored to fit — one line of question, three short choices.
    private func checkCard(_ card: LessonCard) -> some View {
        let picked = answers[index]
        return VStack(alignment: .leading, spacing: 0) {
            CardTypeLabel("QUICK CHECK")
                .padding(.leading, 24).padding(.top, 30)

            Text(card.question)
                .font(Theme.font(21, .heavy))
                .lineSpacing(21 * 0.32)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24).padding(.top, 12)

            VStack(spacing: 10) {
                ForEach(Array(card.choices.enumerated()), id: \.offset) { i, choice in
                    answerRow(choice, at: i, correct: card.answer, picked: picked)
                }
            }
            .padding(.horizontal, 20).padding(.top, 24)

            if picked != nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text(card.why)
                        .font(Theme.font(16, .bold))
                        .lineSpacing(16 * 0.5)
                        .foregroundStyle(Theme.hex(0x7C6F68))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("No coins for this one. Finishing the lesson pays.")
                        .font(Theme.font(12.5, .heavy))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.card))
                .padding(.horizontal, 20).padding(.top, 16)
                .transition(.opacity)
            }

            Spacer(minLength: 0)
        }
        .animation(.easeOut(duration: 0.2), value: picked)
    }

    private func answerRow(_ choice: String, at i: Int, correct: Int, picked: Int?) -> some View {
        let locked = picked != nil
        let isCorrect = locked && i == correct
        let isPicked = picked == i
        return Button {
            guard !locked else { return }
            answers[index] = i
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    Circle()
                        .fill(isCorrect ? Theme.mint : Color.clear)
                        .overlay(Circle().strokeBorder(isCorrect ? .clear : Theme.hex(0xDDD2C0),
                                                       lineWidth: 2))
                        .frame(width: 22, height: 22)
                    if isCorrect {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
                Text(choice)
                    .font(Theme.font(15.5, isCorrect ? .heavy : .bold))
                    .foregroundStyle(isCorrect ? Theme.ink : Theme.hex(0x7C6F68))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                if isPicked && !isCorrect {
                    Text("you picked")
                        .font(Theme.font(11.5, .heavy))
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isCorrect ? Theme.mintSoft : Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isCorrect ? Theme.mint : Theme.hairline,
                              lineWidth: isCorrect ? 2 : 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!locked)
    }

    // MARK: - Bottom bar

    /// The bar's whole block: the 52pt capsule plus its 8/4 padding. The coach
    /// overlay lifts its own copy by exactly this, so "Got it" never lands on the heart.
    private static let barBlock: CGFloat = 52 + 8 + 4

    /// One pill, not two. Reading on is the primary move, so a coral Ask Kin beside the
    /// tools made the smallest promise the loudest thing on the card — and the panel
    /// behind it can only say Kin doesn't read the card. Kin now sits inside the same
    /// white bar as save/share/flag, split by the divider the Home chip uses, and keeps
    /// the mascot rather than becoming a fourth grey glyph.
    private var bottomBar: some View {
        HStack(spacing: 0) {
            // 44pt squares at a 6pt gap keep the old 50pt pitch between glyphs.
            HStack(spacing: 6) {
                Button(action: toggleSave) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(isSaved ? Theme.coral : Theme.muted)
                        .scaleEffect(heartPop ? 1.15 : 1)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(isSaved ? "Remove from saved cards" : "Save this card")

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                Button { reporting = true } label: {
                    Image(systemName: "flag")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Report a problem with this card")
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Theme.chipDivider)
                .frame(width: 1, height: 22)

            Button { askKin = true } label: {
                HStack(spacing: 8) {
                    SlimeAvatar(speciesID: state.activeChibiID, size: 30)
                    Text("Ask Kin")
                        .font(Theme.font(15, .heavy))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                // The button no longer paints its own background, so without this the
                // gap between the face and the label would not be tappable.
                .contentShape(Rectangle())
            }
            .buttonStyle(PressStyle())
        }
        .frame(height: 52)
        .background(Capsule().fill(Theme.card))
        .padding(.horizontal, 20)
        .padding(.top, 8).padding(.bottom, 4)
    }

    /// The reward rides on the button because that is where the decision gets made.
    /// A re-read pays nothing, so the coin pill drops rather than promise coins the
    /// ledger will not post.
    private var finishButton: some View {
        let pays = !state.completedLessons.contains(lesson.id)
        return Button(action: advance) {
            HStack(spacing: 9) {
                Text("Finish")
                    .font(Theme.font(17, .heavy))
                    .foregroundStyle(Theme.onDarkWarm)
                if pays {
                    HStack(spacing: 5) {
                        CoinDisc(size: 12)
                        Text("+\(lesson.reward)")
                            .font(Theme.font(13.5, .black))
                            .foregroundStyle(Theme.onDarkWarm)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Capsule().fill(Theme.onDarkWarm.opacity(0.2)))
                }
            }
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.coral))
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(pays ? "Finish lesson, earns \(lesson.reward) coins"
                                 : "Finish lesson")
        .padding(.horizontal, 20).padding(.top, 12)
        .transition(.opacity)
    }

    private var isSaved: Bool {
        guard let card else { return false }
        return state.isSaved(lessonID: lesson.id, index: card.index)
    }

    private var shareText: String {
        guard let card else { return lesson.title }
        return card.kind == .check ? card.question : card.body
    }

    /// Ask Kin is drawn so the reader's layout is right, and says plainly what it
    /// does today rather than pretending to answer the card.
    private var askKinSheet: some View {
        VStack(spacing: 16) {
            slime(size: 120, expression: .wink)
            Text("Kin is cheering, not explaining")
                .font(Theme.font(22, .black))
                .foregroundStyle(Theme.ink)
            Text("Kin doesn't read the card you're on, so the quick check at the end of the deck is the part that makes it stick.")
                .font(Theme.font(15, .bold))
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.hex(0x7C6F68))
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .presentationDetents([.height(370)])
        .presentationCornerRadius(28)
    }

    // MARK: - Report

    /// The flag sheet. Same paper-and-capsule furniture as Ask Kin, so flagging a
    /// card doesn't feel like a different app. It never says "send": the flag is
    /// written to `GameState.cardReports` on this phone and there is no backend
    /// to receive it, so promising a person will read it would be a lie.
    private var reportSheet: some View {
        VStack(spacing: 14) {
            Text("Something wrong with this card?")
                .font(Theme.font(21, .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 30)

            Text("Flags stay on this phone for now. Nothing gets sent anywhere.")
                .font(Theme.font(14, .bold))
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.hex(0x7C6F68))
                .padding(.horizontal, 6)

            VStack(spacing: 10) {
                ForEach(CardReportReason.allCases) { reason in
                    reasonRow(reason)
                }
            }

            Spacer(minLength: 0)

            Button(action: flagCard) {
                Text("Flag it")
                    .font(Theme.font(17, .heavy))
                    .foregroundStyle(Theme.onDarkWarm)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Theme.coral))
                    .opacity(reportReason == nil ? 0.45 : 1)
            }
            .buttonStyle(PressStyle())
            .disabled(reportReason == nil)
            .padding(.bottom, 26)
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .presentationDetents([.height(440)])
        .presentationCornerRadius(28)
    }

    private func reasonRow(_ reason: CardReportReason) -> some View {
        let picked = reportReason == reason
        return Button { reportReason = reason } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(picked ? Theme.mint : Color.clear)
                        .overlay(Circle().strokeBorder(picked ? .clear : Theme.hex(0xDDD2C0),
                                                       lineWidth: 2))
                        .frame(width: 22, height: 22)
                    if picked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
                Text(reason.label)
                    .font(Theme.font(15.5, picked ? .heavy : .bold))
                    .foregroundStyle(picked ? Theme.ink : Theme.hex(0x7C6F68))
                Spacer(minLength: 6)
            }
            .padding(.horizontal, 16).padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(picked ? Theme.mintSoft : Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(picked ? Theme.mint : Theme.hairline,
                              lineWidth: picked ? 2 : 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func flagCard() {
        guard let card, let reason = reportReason else { return }
        state.reportCard(lessonID: lesson.id, index: card.index, reason: reason)
        reporting = false
        state.show("Good catch. Flagged on this phone.")
    }

    // MARK: - Coach overlay

    /// Shown once, ever. The line removes pressure rather than explaining the UI twice.
    private var coachOverlay: some View {
        ZStack {
            Theme.hex(0x2E2622).opacity(0.7).ignoresSafeArea()

            HStack(spacing: 16) {
                zoneHint("tap here\nto go back", 15).frame(width: 112)
                Rectangle().fill(Theme.mint).frame(width: 2)
                zoneHint("tap here\nto go forward", 21)
            }
            .padding(.horizontal, 14)
            // Both coach blocks ride the same lift, so the slime and its line keep
            // sitting below the dashed zones instead of landing inside them.
            .padding(.top, 46).padding(.bottom, 210 + Self.barBlock)

            VStack(spacing: 18) {
                Spacer()
                HStack(spacing: 12) {
                    slime(size: 78, expression: .wink)
                    Text("Leave whenever you like — I'll keep your place.")
                        .font(Theme.font(15, .heavy))
                        .foregroundStyle(Theme.onDarkWarm)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)

                Button {
                    state.markTapCoachSeen()
                    withAnimation(.easeOut(duration: 0.2)) { showCoach = false }
                } label: {
                    Text("Got it")
                        .font(Theme.font(17, .heavy))
                        .foregroundStyle(Theme.onDarkWarm)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Theme.coral))
                }
                .buttonStyle(PressStyle())
                // The overlay's bottom edge is the bar's bottom edge, so the button has
                // to clear the whole bar block to keep the air it was designed with.
                .padding(.horizontal, 24).padding(.bottom, 30 + Self.barBlock)
            }
        }
        .transition(.opacity)
    }

    /// The hint sits high in its zone rather than dead centre — the middle of the
    /// screen is where a card's own copy is, and two blocks of text on top of each
    /// other read as neither.
    private func zoneHint(_ text: String, _ size: CGFloat) -> some View {
        Text(text)
            .font(Theme.font(size, .heavy))
            .multilineTextAlignment(.center)
            .foregroundStyle(Theme.onDarkWarm)
            .padding(.top, 54)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.onDarkWarm.opacity(0.34),
                              style: StrokeStyle(lineWidth: 2, dash: [7, 6])))
    }

    // MARK: - Coins flying home

    /// Five discs arc from the slime into the coin chip, so the eye lands on the
    /// chip rather than on the button that was just pressed.
    private var coinArc: some View {
        ZStack(alignment: .topTrailing) {
            ForEach(0..<5, id: \.self) { i in
                let t = arc[i]
                CoinDisc(size: 17 - CGFloat(i) * 2)
                    .opacity(flying ? (1 - Double(i) * 0.16) * (1 - t * 0.55) : 0)
                    .offset(x: -230 * (1 - t) + 26 * sin(t * .pi),
                            y: 430 * (1 - t) - 110 * sin(t * .pi))
            }
        }
        .padding(.trailing, 34).padding(.top, 52)
        .allowsHitTesting(false)
    }

    // MARK: - Behaviour

    /// Stepping past the last card *is* finishing: it pays and lands on the one
    /// complete screen. There used to be a "That's the lesson" card with its own
    /// Finish button before that screen — two celebrations for one lesson.
    private func advance() {
        guard index < cards.count, !flying else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if index == cards.count - 1 {
            withAnimation(.easeOut(duration: 0.2)) { index += 1 }
            finish()
            return
        }
        withAnimation(.easeOut(duration: 0.2)) { index += 1 }
        state.setDeckProgress(lesson.id, card: index)
    }

    private func back() {
        guard index > 0 else { return }
        withAnimation(.easeOut(duration: 0.2)) { index -= 1 }
    }

    private func toggleSave() {
        guard let card else { return }
        let saved = state.toggleSaved(lessonID: lesson.id, index: card.index)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard saved else { return }
        withAnimation(.spring(response: 0.14, dampingFraction: 0.5)) { heartPop = true }
        withAnimation(.spring(response: 0.14, dampingFraction: 0.5).delay(0.12)) { heartPop = false }
    }

    private func finish() {
        // The ledger is idempotent, so a second call pays 0 — which used to wipe the
        // "+20" off the complete screen even though the coins had landed. Finishing
        // happens once.
        guard !finishing else { return }
        finishing = true
        paid = state.completeLesson(id: lesson.id, reward: lesson.reward)
        if paid > 0 {
            flying = true
            for i in 0..<arc.count {
                withAnimation(.easeInOut(duration: 0.42).delay(Double(i) * 0.06)) { arc[i] = 1 }
            }
        }
        Task {
            try? await Task.sleep(for: .seconds(paid > 0 ? 0.78 : 0.12))
            finished = true
        }
    }

    private func slime(size: CGFloat,
                       animation: ChibiAnimation = .idle,
                       expression: SlimeExpression? = .idle,
                       replay: Int = 0) -> some View {
        SproutImage(speciesID: state.activeChibiID,
                    level: state.activeChibi.level,
                    skin: state.activeChibi.skinID,
                    animation: animation, replay: replay, size: size)
    }

    private func bodyCopy(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(19.5, .bold))
            .lineSpacing(19.5 * 0.5)
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 24).padding(.trailing, 26)
    }
}

// MARK: - Lesson complete

/// One warm screen instead of a dump back to the map: what you learned in one line,
/// the coins, one forward move, one quiet way out.
struct LessonCompleteView: View {
    let lesson: Lesson
    let paid: Int
    let onNext: (Lesson) -> Void
    let onClose: () -> Void

    @EnvironmentObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var burst = false
    @State private var cheers = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Theme.card))
                }
                .accessibilityLabel("Close")
                Spacer()
                CoinBadge(coins: state.coins)
            }
            .padding(.horizontal, 22).padding(.top, 10)

            ZStack {
                // The still draws its character low in its own box, so the rays are
                // dropped to sit around him rather than around the frame.
                Burst().stroke(Theme.coin.opacity(0.5),
                               style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 250, height: 250)
                    .offset(y: 32)
                    .scaleEffect(burst ? 1 : 0.6)
                    .opacity(burst ? 1 : 0)
                    .rotationEffect(.degrees(burst ? 0 : -18))
                SproutImage(speciesID: state.activeChibiID,
                            level: state.activeChibi.level,
                            skin: state.activeChibi.skinID,
                            animation: .celebrate, replay: cheers, size: 170)
                    .scaleEffect(burst ? 1 : 0.82)
            }
            .padding(.top, 18)

            Text(lesson.takeaway)
                .font(Theme.font(24, .heavy))
                .lineSpacing(24 * 0.34)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 30).padding(.top, 8)

            if paid > 0 {
                HStack(spacing: 9) {
                    CoinDisc(size: 26)
                    Text("+\(paid)")
                        .font(Theme.font(30, .black))
                        .foregroundStyle(Theme.coinDark)
                }
                .padding(.horizontal, 22).padding(.vertical, 10)
                .background(Capsule().fill(Theme.coinSoft))
                .scaleEffect(burst ? 1 : 0.7)
                .opacity(burst ? 1 : 0)
                .padding(.top, 16)
            }

            trackProgress
                .padding(.top, 18)

            Spacer(minLength: 12)

            if let next = nextLesson {
                nextCard(next)
                Button(action: onClose) {
                    Text("Not now")
                        .font(Theme.font(14.5, .heavy))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 14).padding(.bottom, 20)
            } else {
                Button(action: onClose) {
                    Text("Back to Learn")
                        .font(Theme.font(18, .heavy))
                        .foregroundStyle(Theme.onDarkWarm)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Theme.coral))
                }
                .buttonStyle(PressStyle())
                .padding(.horizontal, 22).padding(.bottom, 28)
            }
        }
        .onAppear {
            guard !reduceMotion else { burst = true; return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { burst = true }
        }
        // He keeps cheering while you are on this screen. The emote is a one-shot of
        // about a second, so on its own it is over before anyone looks up.
        .onReceive(Timer.publish(every: 2.4, on: .main, in: .common).autoconnect()) { _ in
            guard !reduceMotion else { return }
            cheers += 1
        }
    }

    /// How far the track has come. It can only ever go up, so it is safe to show:
    /// finishing a lesson should visibly move something.
    private var trackProgress: some View {
        let run = Catalog.lessons(in: lesson.trackID)
        let done = run.filter { state.completedLessons.contains($0.id) }.count
        return VStack(spacing: 8) {
            Text("\(done) of \(run.count) in \(Catalog.track(lesson.trackID).name)")
                .font(Theme.font(13, .heavy))
                .foregroundStyle(Theme.muted)
            ProgressTrack(fraction: Double(done) / Double(max(run.count, 1)),
                          tint: TrackTint.accent(lesson.trackID))
                .frame(width: 170)
        }
    }

    /// One choice, not a menu.
    private func nextCard(_ next: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT IN \(Catalog.track(next.trackID).name.uppercased())")
                .font(Theme.font(11.5, .heavy))
                .tracking(1.1)
                .foregroundStyle(Theme.muted)

            Text(next.title)
                .font(Theme.font(19, .heavy))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            Text("\(next.cards.count) cards · \(next.minutes) min · +\(next.reward)")
                .font(Theme.font(13, .bold))
                .foregroundStyle(Theme.muted)
                .padding(.top, 4)

            Button { onNext(next) } label: {
                Text("Start")
                    .font(Theme.font(17, .heavy))
                    .foregroundStyle(Theme.onDarkWarm)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
            .padding(.top, 16)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(Theme.cardEdge, lineWidth: 1))
        .padding(.horizontal, 22)
    }

    /// The next unfinished lesson in the same track, else anything else unfinished in
    /// it. Nothing left means the screen has one button instead of two — never a
    /// consolation card.
    private var nextLesson: Lesson? {
        let run = Catalog.lessons(in: lesson.trackID)
        guard let here = run.firstIndex(where: { $0.id == lesson.id }) else { return nil }
        return run[(here + 1)...].first { !state.completedLessons.contains($0.id) }
            ?? run.first { $0.id != lesson.id && !state.completedLessons.contains($0.id) }
    }
}

// MARK: - Shared pieces

/// Coral buttons darken on press; white cards scale slightly with no colour change.
struct PressStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.05 : 0)
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// The uppercase label above a key idea, an example, or a check.
struct CardTypeLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(Theme.font(12, .heavy))
            .tracking(1.7)
            .foregroundStyle(Theme.muted)
    }
}


/// The rays behind the mascot on the complete screen. Twelve short spokes, alternating
/// length, drawn rather than animated as a sprite so Reduce Motion can simply show them
/// at rest.
private struct Burst: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        for i in 0..<12 {
            let a = Double(i) / 12 * 2 * .pi - .pi / 2
            let inner = r.width * 0.36
            let outer = r.width * (i.isMultiple(of: 2) ? 0.48 : 0.43)
            p.move(to: CGPoint(x: c.x + inner * cos(a), y: c.y + inner * sin(a)))
            p.addLine(to: CGPoint(x: c.x + outer * cos(a), y: c.y + outer * sin(a)))
        }
        return p
    }
}
