import SwiftUI

/// Where a lesson can be opened from. The reader is a full-screen cover rather than
/// a push, so it can own the whole screen and close with one ✕.
struct ReadingRequest: Identifiable, Equatable {
    let lesson: Lesson
    var startAt = 0
    /// Changes whenever a new deck is opened, so the cover rebuilds when the student
    /// takes the forward move on the complete screen.
    var id: String { "\(lesson.id)#\(startAt)" }
}

/// Learn, root of the tab.
///
/// Nothing here is an empty state: without an in-progress deck the Continue hero is
/// absent, without Canvas the "Because of your week" section is absent, and the
/// screen simply gets shorter.
///
/// Two things carry the visual weight, both learned from what shipping learning apps
/// actually do: **every offer has cover art**, and section headers are real titles
/// rather than 11pt uppercase micro-labels. Without those this screen reads as a
/// settings list, which is what it looked like on the first build.
struct LearnView: View {
    @EnvironmentObject var state: AppState

    /// Which half of the tab is showing. Remembered, so a student who comes for
    /// the lessons lands on the lessons — the one scroll this replaced put 600pt
    /// of puzzles between them and today's card every single time.
    @AppStorage("play.half") private var halfRaw = Half.puzzles.rawValue
    private var half: Half { Half(rawValue: halfRaw) ?? .puzzles }
    enum Half: String, CaseIterable {
        case puzzles, lessons
        var label: String { self == .puzzles ? "Puzzles" : "Lessons" }
    }

    @State private var previewing: Lesson?
    /// Set by the preview sheet's Start, read once the sheet has finished dismissing.
    /// Presenting a cover while a sheet is still on screen drops the cover.
    @State private var pending: Lesson?
    @State private var reading: ReadingRequest?
    @State private var explainingRating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    header

                    halfSwitch

                    // Two halves behind one switch (2026-09-11). They were one scroll,
                    // puzzles first — the retention evidence is theirs (GAMES-PLAN.md
                    // §2) — but a lesson-minded student then scrolled past every puzzle
                    // to reach today's card. Each half owns the screen now, and the
                    // switch's dot says when the other half's daily thing is still open.
                    if half == .puzzles {
                    VStack(alignment: .leading, spacing: 12) {
                        puzzlesTitle
                        puzzleHero
                        puzzleList
                    }
                    } else {

                    if let cont = state.continueLesson {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Pick up where you left off")
                            continueHero(cont.lesson, card: cont.card)
                        }
                    }

                    let suggestions = state.lessonSuggestions
                    if !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Because of your week",
                                         "Picked from what's actually due")
                            VStack(spacing: 10) {
                                ForEach(suggestions) { suggestionCard($0) }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    if let today = todaysCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Today's card", "Two minutes, then you're done")
                            lessonHero(today).padding(.horizontal, 20)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Tracks")
                        trackShelf
                    }

                    savedRow
                    }
                }
                .padding(.top, 4)
                .animation(.easeInOut(duration: 0.18), value: halfRaw)
                .padding(.bottom, Theme.tabClearance)
            }
            .background(Theme.paper)
            // Scrolled section titles used to run straight under the clock. A solid
            // band the height of the status bar, then a short fade, reads as the
            // page continuing under glass rather than text hitting the clock.
            .overlay(alignment: .top) {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Theme.paper.frame(height: geo.safeAreaInsets.top)
                        LinearGradient(colors: [Theme.paper, Theme.paper.opacity(0)],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 22)
                    }
                    .ignoresSafeArea(edges: .top)
                }
                .allowsHitTesting(false)
            }
            .navigationDestination(for: LearnRoute.self) { route in
                switch route {
                case .track(let id): TrackMapView(trackID: id, onRead: open)
                case .saved: SavedCardsView(onRead: open)
                case .dailyWord: WordleView()
                case .trace: TraceView()
                case .pearls: PearlsView()
                case .balance: BalanceView()
                case .sort: SortView()
                case .weave: WeaveView()
                }
            }
        }
        .sheet(item: $previewing, onDismiss: startPending) { lesson in
            LessonPreviewSheet(lesson: lesson) {
                pending = lesson
                previewing = nil
            }
        }
        .fullScreenCover(item: $reading) { request in
            LessonDeckView(lesson: request.lesson, startAt: request.startAt) { next in
                reading = ReadingRequest(lesson: next)
            }
            // Without this the cover reuses the previous deck's view — and with it
            // that deck's card index and finished flag.
            .id(request.id)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // Not the word "Learn". The tab bar says that four points below, and a
                // line that repeats the tab is a line that earns nothing — Duolingo names
                // the unit you are in, Chick-fil-A greets you, Apple News just starts.
                // This names where you are: the track you are part way through.
                // The title and the coin chip, nothing else. NYT Games' home is a
                // title and tiles with no counters above them (Mobbin
                // 8c796715-7244-416a-8d9d-f6211323d7d2); the month tally that sat
                // here was a second signal over a page whose one job is today's set.
                Text(headline)
                    .font(Theme.font(34, .black))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
            CoinBadge(coins: state.coins)
                .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    /// An invitation, always. It used to become the name of the track a half-read
    /// lesson belonged to — right when the page was Learn and that track was the
    /// unit you were in. On Play the unit is today's set, and the Continue hero
    /// below already names its track; a page titled "Personal finance" over six
    /// puzzles named nothing.
    private var headline: String { "Start anywhere" }

    /// Imprint's section grammar: a big bold title and one plain sentence under it,
    /// then the goods. 21/13.5 rather than 19/13, so a title outweighs a card title.
    private func sectionTitle(_ title: String, _ sub: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(Theme.font(21, .black))
                .foregroundStyle(Theme.ink)
            if let sub {
                Text(sub)
                    .font(Theme.font(13.5, .bold))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Switch

    /// The Calendar's Week / Month switch, one size up: a sunk track, the chosen
    /// half lifted onto card white. The coral dot that marked the other half's
    /// open daily thing came off on 2026-09-12: Apple News' Puzzles page is a
    /// title and "Today's Puzzles" with nothing blinking above it (Mobbin
    /// a2319e2f-b25d-41ff-8b15-b0f9d35dc619), and the dot was a third signal in a
    /// header that already had two.
    ///
    /// The track draws 40pt tall; each half's hit area is 44. The extra is
    /// transparent and taken back from the layout, so nothing under it moves.
    private var halfSwitch: some View {
        HStack(spacing: 0) {
            ForEach(Half.allCases, id: \.self) { h in segment(h) }
        }
        .padding(3)
        .background(Capsule().fill(Theme.paperSunk).padding(.vertical, 5))
        .padding(.vertical, -5)
        .padding(.horizontal, 24)
    }

    private func segment(_ h: Half) -> some View {
        let on = h == half
        return Text(h.label)
            .font(Theme.font(14, .black))
            .foregroundStyle(on ? Theme.ink : Theme.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                Capsule()
                    .fill(on ? Theme.card : .clear)
                    .shadow(color: on ? Theme.hex(0x2E2622).opacity(0.10) : .clear, radius: 3, y: 1)
                    .padding(.vertical, 5)
            )
            .contentShape(Capsule())
            .onTapGesture {
                guard !on else { return }
                UISelectionFeedbackGenerator().selectionChanged()
                halfRaw = h.rawValue
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Self.segmentLabel(h))
            .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
    }

    /// What a half of the switch says: its name, and nothing about what is open.
    /// It used to add ", something still open today" when the dot was showing.
    static func segmentLabel(_ h: Half) -> String { h.label }

    // MARK: - Continue

    /// The one big thing on the screen. Resumes straight into the deck — it already
    /// says which card you're on, so a preview sheet in the way would be a second tap.
    /// Same grammar as today's card and the track rail (Imprint's, 2026-09-11): the
    /// cover is the tile, the words sit under it on the page. It used to be the one
    /// boxed card between two unboxed ones. The progress bar runs the full width
    /// under the meta line, where a bar reads as "this far through".
    private func continueHero(_ lesson: Lesson, card: Int) -> some View {
        Button { reading = ReadingRequest(lesson: lesson, startAt: card) } label: {
            VStack(alignment: .leading, spacing: 0) {
                LessonCover(lesson: lesson, height: 172, corner: 20)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.title)
                            .font(Theme.font(18, .black))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Card \(card + 1) of \(lesson.cards.count) · \(Catalog.track(lesson.trackID).name)")
                            .font(Theme.font(13, .bold))
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer(minLength: 4)
                    Text("Resume")
                        .font(Theme.font(14.5, .heavy))
                        .foregroundStyle(Theme.onDarkWarm)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.coral))
                }
                .padding(.top, 12).padding(.horizontal, 4)

                ProgressTrack(fraction: Double(card) / Double(max(lesson.cards.count - 1, 1)))
                    .padding(.top, 10).padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
        }
        .buttonStyle(PressStyle())
        // Without this VoiceOver reads the cover's figure captions ("osmosis:
        // movement of water, you can highlight this…") and never the lesson.
        .accessibilityLabel("Resume \(lesson.title), card \(card + 1) of \(lesson.cards.count)")
    }

    // MARK: - Picks

    /// Picked off the real Canvas feed. This is why the tab lives inside this app.
    private func suggestionCard(_ s: Catalog.Suggestion) -> some View {
        Button { previewing = s.lesson } label: {
            HStack(spacing: 13) {
                LessonThumb(lesson: s.lesson, size: 64)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        Circle().fill(Theme.coral).frame(width: 6, height: 6)
                        Text(reasonLabel(s.task))
                            .font(Theme.font(11, .heavy))
                            .foregroundStyle(Theme.coralDeep)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Capsule().fill(Theme.coralSoft))

                    Text(s.lesson.title)
                        .font(Theme.font(16.5, .heavy))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)

                    Text("\(s.lesson.cards.count) cards · \(s.lesson.minutes) min · +\(s.lesson.reward)")
                        .font(Theme.font(12, .bold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 2)
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.coral))
            }
            .padding(13)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.card))
        }
        .buttonStyle(PressStyle())
    }

    /// Today's lesson the way Imprint shows a title: the cover is the whole tile,
    /// and the name, the size and the coin sit under it in plain type on the page —
    /// not in a second box, not over the art. It was a 60pt thumbnail in a row.
    private func lessonHero(_ lesson: Lesson) -> some View {
        Button { previewing = lesson } label: {
            VStack(alignment: .leading, spacing: 0) {
                LessonCover(lesson: lesson, height: 172, corner: 20)
                Text(lesson.title)
                    .font(Theme.font(18, .black))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12).padding(.horizontal, 4)
                HStack(alignment: .firstTextBaseline) {
                    Text("\(lesson.cards.count) cards · \(lesson.minutes) min")
                        .font(Theme.font(13, .bold))
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    HStack(spacing: 5) {
                        CoinDisc(size: 13)
                        Text("+\(lesson.reward)")
                            .font(Theme.font(12.5, .heavy))
                            .foregroundStyle(Theme.coinDark)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Capsule().fill(Theme.coinSoft))
                }
                .padding(.top, 5).padding(.horizontal, 4)
            }
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("\(lesson.title), \(lesson.cards.count) cards · \(lesson.minutes) min, +\(lesson.reward)")
    }

    // MARK: - Tracks

    private var trackShelf: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Catalog.tracks) { track in
                    NavigationLink(value: LearnRoute.track(track.id)) {
                        trackCard(track)
                    }
                    .buttonStyle(PressStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollClipDisabled()
    }

    /// Imprint's rail: a square of art, the name and the count in plain type under
    /// it, nothing boxed. The square is the cover of the next lesson you would read
    /// in that track — real content that changes as you go — instead of the track's
    /// icon on a swatch inside a white card, which was the weakest thing on the page.
    private func trackCard(_ track: Track) -> some View {
        let run = Catalog.lessons(in: track.id)
        let done = run.filter { state.completedLessons.contains($0.id) }.count
        let next = run.first { !state.completedLessons.contains($0.id) } ?? run.first
        return VStack(alignment: .leading, spacing: 0) {
            Group {
                if let next {
                    LessonCover(lesson: next, height: 148, corner: 18)
                } else {
                    TrackCover(trackID: track.id, height: 148)
                }
            }
            .frame(width: 148, height: 148)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(track.name)
                .font(Theme.font(15, .black))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .padding(.top, 10).padding(.horizontal, 2)

            HStack(spacing: 6) {
                ProgressRing(fraction: Double(done) / Double(max(run.count, 1)),
                             size: 14, tint: TrackTint.accent(track.id))
                Text("\(done) of \(run.count)")
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.top, 3).padding(.horizontal, 2)
        }
        .frame(width: 148, alignment: .topLeading)
    }

    // MARK: - Play

    /// The six puzzles, in the shape of the NYT Games hub (Mobbin, 2026-09-11): one
    /// puzzle featured big with its board, its name, a tagline and a Play button,
    /// and the rest as calm list rows — a badge on a pale panel, a name, a tagline.
    /// Before this they were six saturated blocks in a grid, which read as a kids'
    /// app; the mascot research already had the palette reading young.
    ///
    /// Daily Word and Number Line moved here from the Games tab on 2026-09-06 so
    /// the bar could drop to five (design/hicks-law-plan.md); the four games of
    /// 2026-09-08 joined them (design/GAMES-PLAN.md).
    /// "Today's puzzles", not "Play": the tab already says Play, four points below,
    /// and the Game Boy that used to sit here is now the tab's own icon.
    private var puzzlesTitle: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's puzzles")
                    .font(Theme.font(19, .black))
                    .foregroundStyle(Theme.ink)
                Text(playLine)
                    .font(Theme.font(13, .bold))
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 8)
            // The one competitive number that works with nobody else on the app.
            // Hidden until the first result, so a new student is not handed a score
            // they have not played for.
            if state.rating.settled > 0 {
                Button { explainingRating = true } label: {
                    VStack(spacing: 0) {
                        Text(state.rating.display)
                            .font(Theme.font(15, .black))
                            .foregroundStyle(Theme.ink)
                        Text("RATING")
                            .font(Theme.font(8.5, .black)).tracking(1)
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rating \(state.rating.display). What it means")
            }
        }
        .padding(.horizontal, 24)
        .sheet(isPresented: $explainingRating) { ratingSheet }
    }

    /// One line, on a tap of the chip. The chip itself says only the number.
    static let ratingExplainer = "Goes up when you solve a hard one, down when you miss an easy one. Chess.com's puzzle rating, for puzzles."

    private var ratingSheet: some View {
        VStack(spacing: 12) {
            Text(state.rating.display)
                .font(Theme.font(34, .black))
                .foregroundStyle(Theme.ink)
                .padding(.top, 26)
            Text(Self.ratingExplainer)
                .font(Theme.font(15, .bold))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .presentationDetents([.height(196)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(26)
    }

    private var playLine: String {
        Self.playLine(claimed: state.playClaimedToday, total: playTiles.count,
                      left: playTiles.filter { !$0.played }.count)
    }

    /// "Six today. First finish pays 30." / "Paid. Two more for the result line."
    /// Coins are paid, in the same word the rest of the app uses; "banks" and
    /// "Banked" were this page's own dialect.
    static func playLine(claimed: Bool, total: Int, left: Int) -> String {
        if !claimed { return "\(countWord(total)) today. First finish pays 30." }
        if left == 0 { return "All done today. New ones tomorrow." }
        return "Paid. \(countWord(left)) more for the result line."
    }

    private static func countWord(_ n: Int) -> String {
        ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"].indices.contains(n - 1)
            ? ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"][n - 1] : "\(n)"
    }

    /// The one to play next: the first still unplayed, in the fixed order. Once all
    /// six are done there is no hero — the list carries the day's results.
    private var featured: PlayTile? { playTiles.first { !$0.played } }

    @ViewBuilder
    private var puzzleHero: some View {
        if let tile = featured {
            NavigationLink(value: tile.route) {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        MiniBoard(glyph: tile.glyph, ink: tile.ink, size: 84)
                        Text(tile.name)
                            .font(Theme.font(21, .black))
                            .foregroundStyle(Theme.ink)
                            .padding(.top, 6)
                        Text("\(tile.tagline) · \(tile.line)")
                            .font(Theme.font(13, .bold))
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22).padding(.bottom, 18)
                    .background(tile.fill.opacity(0.32))

                    Text("Play")
                        .font(Theme.font(15, .black))
                        .foregroundStyle(.white)
                        .frame(width: 150)
                        .padding(.vertical, 13)
                        .background(Capsule().fill(Theme.coral)
                            .shadow(color: Theme.coral.opacity(0.28), radius: 12, y: 5))
                        .padding(.vertical, 18)
                }
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.card))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
            }
            .buttonStyle(PressStyle(scale: 0.98))
            .padding(.horizontal, 20)
            .accessibilityLabel("\(tile.name), \(tile.tagline), \(tile.line). Play.")
        }
    }

    /// Everything but the featured one, unplayed first. Every row is on screen at
    /// once — a rail used to show two and a sliver, and a puzzle you cannot see is a
    /// puzzle you do not play.
    private var puzzleList: some View {
        let tiles = playTiles.filter { $0.id != featured?.id }
        let ordered = tiles.filter { !$0.played } + tiles.filter { $0.played }
        return VStack(spacing: 8) {
            ForEach(ordered) { tile in
                NavigationLink(value: tile.route) {
                    puzzleRow(tile)
                }
                .buttonStyle(PressStyle(scale: 0.98))
                .accessibilityLabel("\(tile.name), \(tile.played ? tile.line : tile.tagline)")
            }
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.34, dampingFraction: 0.74), value: ordered.map(\.id))
    }

    /// NYT's list card: the badge carries the game's colour, the panel is a pale
    /// wash of it, and the words are ink on that. Played rows swap the tagline for
    /// the result, which is the line worth reading twice.
    private func puzzleRow(_ tile: PlayTile) -> some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tile.fill)
                .frame(width: 46, height: 46)
                .overlay { MiniBoard(glyph: tile.glyph, ink: tile.ink, size: 30) }
            VStack(alignment: .leading, spacing: 3) {
                Text(tile.name)
                    .font(Theme.font(16.5, .black))
                    .foregroundStyle(Theme.ink)
                Text(tile.played ? tile.line : tile.tagline)
                    .font(Theme.font(12.5, .bold))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 12).padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(tile.fill.opacity(0.22)))
    }

    /// One tile per game. `played` is whether today's is done; it sorts to the end.
    private struct PlayTile: Identifiable {
        let route: LearnRoute
        let name: String
        /// What the puzzle is, in four or five words, the way NYT captions each of
        /// its games ("Crack Clues", "Solve in Seconds"). Dry, no exclamation mark.
        let tagline: String
        let line: String
        let played: Bool
        let fill: Color
        let ink: Color
        let glyph: PlayGlyph
        var id: String { name }
    }

    private var playTiles: [PlayTile] {
        let today = state.game.effectiveDay
        // No "+30" on the tiles (removed 2026-09-10). One finish a day pays it, and
        // six tiles each promising it read as 180 coins on offer — a rail only ever
        // showed two of them, and the grid shows all six. The section line says it
        // once, the way it actually works: "First finish pays 30."
        let number = PlayDeal.number()
        let pearlsDone = state.game.pearlsPlay.lastDay == today
        let balanceDone = state.game.balancePlay.lastDay == today
        let traceDone = state.game.tracePlay.lastDay == today
        let weaveDone = state.game.weavePlay.lastDay == today
        // A lost Sort is over for the day too: four misses, groups shown.
        let sortDone = state.game.sortPlay.lastDay == today
            || SortGame.isOver(state.playProgress(\.sortPlay, for: today) ?? [])
        return [
            PlayTile(route: .dailyWord, name: "Daily Word", tagline: "Five letters, six tries", line: dailyWordLine,
                     played: state.wordleClaimedToday,
                     fill: Theme.hex(0xFFC94D), ink: Theme.hex(0x3A2A05), glyph: .letter("A", Theme.hex(0x7A5C1E))),
            PlayTile(route: .trace, name: "Trace", tagline: "One line, every square",
                     line: traceDone ? "Solved" : "Board \(number)",
                     played: traceDone,
                     fill: Theme.hex(0x9B7BEA), ink: Theme.hex(0x2A1A57), glyph: .trace),
            PlayTile(route: .pearls, name: "Pearls", tagline: "One pearl per reef",
                     line: pearlsDone ? "Solved" : "\(PlayDeal.isSunday() ? "8×8" : "7×7") · reef \(number)",
                     played: pearlsDone,
                     fill: Theme.hex(0x4CA8E8), ink: Theme.hex(0x0B3652), glyph: .pearl),
            PlayTile(route: .balance, name: "Balance", tagline: "Suns and moons, three each",
                     line: balanceDone ? "Solved" : "Grid \(number)",
                     played: balanceDone,
                     fill: Theme.hex(0xA5CE6B), ink: Theme.hex(0x2F4712), glyph: .dots),
            PlayTile(route: .sort, name: "Sort", tagline: "Four groups of four",
                     line: sortDone ? (state.game.sortPlay.lastDay == today ? "Solved" : "See the groups") : "Board \(number)",
                     played: sortDone,
                     fill: Theme.hex(0xF5A15C), ink: Theme.hex(0x5A2A0E), glyph: .sort),
            PlayTile(route: .weave, name: "Weave", tagline: "Find the thread",
                     line: weaveDone ? "Solved" : "Board \(number)",
                     played: weaveDone,
                     fill: Theme.hex(0x5CC8C0), ink: Theme.hex(0x0E4744), glyph: .weave),
        ]
    }

    private var dailyWordLine: String {
        let guesses = state.wordleGuesses(for: state.game.effectiveDay)
        if state.wordleClaimedToday {
            return guesses.count == 1 ? "Solved, first try" : "Solved in \(guesses.count)"
        }
        if guesses.count >= 6 { return "See the answer" }
        return "Word \(WordleGame.puzzleNumber())"
    }

    private var savedRow: some View {
        NavigationLink(value: LearnRoute.saved) {
            HStack(spacing: 13) {
                IconTile(icon: "heart", size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved cards")
                        .font(Theme.font(16, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(state.savedCards.isEmpty
                         ? "Tap the heart while you read"
                         : "\(state.savedCards.count) kept")
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Theme.dim)
            }
            .padding(13)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.card))
            .padding(.horizontal, 20)
        }
        .buttonStyle(PressStyle())
    }

    // MARK: - Picking

    /// One lesson for today, stable within the day and unfinished. Rolls over at
    /// midnight with the rest of the app rather than on a timer of its own.
    private var todaysCard: Lesson? {
        let open = Catalog.lessons.filter { !state.completedLessons.contains($0.id) }
        guard !open.isEmpty else { return nil }
        // Not `hashValue`: Swift seeds String hashing per process, so today's card
        // was a different card on every launch. Summing the scalars is the same
        // number all day, which is the whole meaning of "today's".
        let seed = state.game.effectiveDay.raw.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFFFF }
        let pick = open[seed % open.count]
        // Don't offer the same thing twice on one screen.
        if pick.id == state.continueLesson?.lesson.id
            || state.lessonSuggestions.contains(where: { $0.lesson.id == pick.id }) {
            return open.first { $0.id != pick.id }
        }
        return pick
    }

    private func reasonLabel(_ task: DailyTask) -> String {
        let what = task.detail?.isEmpty == false ? task.detail! : task.title
        guard let due = task.dueAt else { return what }
        return "\(what) · \(DueLabel.of(due))"
    }

    // MARK: - Presenting

    private func open(_ request: ReadingRequest) { reading = request }

    private func startPending() {
        guard let lesson = pending else { return }
        pending = nil
        reading = ReadingRequest(lesson: lesson, startAt: state.deckProgress(lesson.id))
    }
}

// MARK: - Routes

enum LearnRoute: Hashable {
    case track(String)
    case saved
    case dailyWord
    case trace
    case pearls
    case balance
    case sort
    case weave
}

// MARK: - Small pieces

/// "Friday", "Today", "Tomorrow" — the shape a due date takes on a reason strip.
enum DueLabel {
    static func of(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let days = calendar.dateComponents([.day], from: now, to: date).day ?? 0
        if (0...6).contains(days) { return date.formatted(.dateTime.weekday(.wide)) }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}

struct ProgressTrack: View {
    let fraction: Double
    var tint: Color = Theme.mint
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule().fill(tint)
                    .frame(width: geo.size.width * min(max(fraction, 0.04), 1))
            }
        }
        .frame(height: 6)
    }
}

struct ProgressRing: View {
    let fraction: Double
    var size: CGFloat = 28
    var tint: Color = Theme.mint
    var body: some View {
        ZStack {
            Circle().strokeBorder(Theme.hairline, lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
