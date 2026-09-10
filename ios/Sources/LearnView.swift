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

    @State private var previewing: Lesson?
    /// Set by the preview sheet's Start, read once the sheet has finished dismissing.
    /// Presenting a cover while a sheet is still on screen drops the cover.
    @State private var pending: Lesson?
    @State private var reading: ReadingRequest?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    header

                    // First since 2026-09-10, when the tab became Play. The six
                    // puzzles used to sit fifth, in a rail that hid four of them, under
                    // a header that said Play inside a tab that said Learn. The
                    // retention evidence is theirs (GAMES-PLAN.md §2), so they lead;
                    // the lessons follow in the order they always had (PLAY-TAB.md).
                    VStack(alignment: .leading, spacing: 12) {
                        puzzlesTitle
                        puzzleGrid
                    }

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
                            pickRow(today).padding(.horizontal, 20)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Tracks")
                        trackShelf
                    }

                    savedRow
                }
                .padding(.top, 4)
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
                Text(headline)
                    .font(Theme.font(34, .black))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                // The only counter on the screen, and it can only go up. No streak,
                // no target, nothing that resets to zero overnight.
                Text(monthLine)
                    .font(Theme.font(13.5, .bold))
                    .foregroundStyle(Theme.muted)
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

    /// The only counter on the screen, and it can only go up. Both rituals count
    /// (2026-09-10): a Play tab that tallied lessons alone under six puzzles was
    /// keeping score for the wrong half of the page.
    private var monthLine: String {
        let puzzles = state.puzzlesThisMonth
        let lessons = state.lessonsThisMonth
        func n(_ k: Int, _ word: String) -> String { "\(k) \(word)\(k == 1 ? "" : "s")" }
        switch (puzzles, lessons) {
        case (0, 0): return "Two minutes is enough to start"
        case (_, 0): return "\(n(puzzles, "puzzle")) this month"
        case (0, _): return "\(n(lessons, "lesson")) this month"
        default:     return "\(n(puzzles, "puzzle")) and \(n(lessons, "lesson")) this month"
        }
    }

    private func sectionTitle(_ title: String, _ sub: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.font(19, .black))
                .foregroundStyle(Theme.ink)
            if let sub {
                Text(sub)
                    .font(Theme.font(13, .bold))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Continue

    /// The one big thing on the screen. Resumes straight into the deck — it already
    /// says which card you're on, so a preview sheet in the way would be a second tap.
    private func continueHero(_ lesson: Lesson, card: Int) -> some View {
        Button { reading = ReadingRequest(lesson: lesson, startAt: card) } label: {
            VStack(spacing: 0) {
                LessonCover(lesson: lesson, height: 148, corner: 20)
                    .padding(6)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lesson.title)
                                .font(Theme.font(19, .black))
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.leading)
                            Text("Card \(card + 1) of \(lesson.cards.count) · \(Catalog.track(lesson.trackID).name)")
                                .font(Theme.font(12.5, .bold))
                                .foregroundStyle(Theme.muted)
                        }
                        Spacer(minLength: 4)
                        Text("Resume")
                            .font(Theme.font(14.5, .heavy))
                            .foregroundStyle(Theme.onDarkWarm)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Capsule().fill(Theme.coral))
                    }
                    ProgressTrack(fraction: Double(card) / Double(max(lesson.cards.count - 1, 1)))
                }
                .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 15)
            }
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.hex(0x2E2622).opacity(0.06), radius: 14, y: 4))
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

    private func pickRow(_ lesson: Lesson) -> some View {
        Button { previewing = lesson } label: {
            HStack(spacing: 13) {
                LessonThumb(lesson: lesson, size: 60)
                VStack(alignment: .leading, spacing: 3) {
                    Text(lesson.title)
                        .font(Theme.font(16.5, .heavy))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                    Text("\(lesson.cards.count) cards · \(lesson.minutes) min")
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 4)
                HStack(spacing: 5) {
                    CoinDisc(size: 14)
                    Text("+\(lesson.reward)")
                        .font(Theme.font(13, .heavy))
                        .foregroundStyle(Theme.coinDark)
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(Capsule().fill(Theme.coinSoft))
            }
            .padding(13)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.card))
        }
        .buttonStyle(PressStyle())
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

    private func trackCard(_ track: Track) -> some View {
        let run = Catalog.lessons(in: track.id)
        let done = run.filter { state.completedLessons.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: 0) {
            TrackCover(trackID: track.id, height: 92)

            Text(track.name)
                .font(Theme.font(15.5, .heavy))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 11)

            Spacer(minLength: 6)

            HStack(spacing: 8) {
                ProgressRing(fraction: Double(done) / Double(max(run.count, 1)),
                             size: 22, tint: TrackTint.accent(track.id))
                Text("\(done) of \(run.count)")
                    .font(Theme.font(12.5, .heavy))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(10)
        .frame(width: 168, height: 188, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.card))
    }

    // MARK: - Play

    /// The Play rail: Daily Word and Number Line moved here from the Games tab on
    /// 2026-09-06 so the tab bar could drop to five (design/hicks-law-plan.md), and
    /// the four games of 2026-09-08 joined them (design/GAMES-PLAN.md). Six tiles
    /// is past the five-equal-choices rule, so it is a catalog: a rail that sorts
    /// today's unplayed games first and never cuts one. No hero: the one big thing
    /// on this screen stays the lesson.
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
                VStack(spacing: 0) {
                    Text(state.rating.display)
                        .font(Theme.font(15, .black))
                        .foregroundStyle(Theme.ink)
                    Text("RATING")
                        .font(Theme.font(8.5, .black)).tracking(1)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 24)
    }

    private var playLine: String {
        let tiles = playTiles
        let left = tiles.filter { !$0.played }.count
        if !state.playClaimedToday { return "\(Self.countWord(tiles.count)) today. First finish banks 30." }
        if left == 0 { return "All done today. New ones tomorrow." }
        return "Banked. \(Self.countWord(left)) more for the result line."
    }

    private static func countWord(_ n: Int) -> String {
        ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"].indices.contains(n - 1)
            ? ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"][n - 1] : "\(n)"
    }

    /// All six at once. A rail showed two and a sliver, and a puzzle you cannot see
    /// is a puzzle you do not play; NYT and Apple News both lay the day's set out in
    /// full. Six same-shaped tiles is well inside what a glance can hold. Done ones
    /// still sort to the end, so what is left to play is always top-left.
    private var puzzleGrid: some View {
        let tiles = playTiles
        let ordered = tiles.filter { !$0.played } + tiles.filter { $0.played }
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ordered) { tile in
                NavigationLink(value: tile.route) {
                    playTile(tile)
                }
                .buttonStyle(PressStyle(scale: 0.97))
                .accessibilityLabel("\(tile.name), \(tile.line)")
            }
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.34, dampingFraction: 0.74), value: ordered.map(\.id))
    }

    /// One tile per game. `played` is whether today's is done; it sorts to the end.
    private struct PlayTile: Identifiable {
        let route: LearnRoute
        let name: String
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
        // once, the way it actually works: "First finish banks 30."
        let number = PlayDeal.number()
        let pearlsDone = state.game.pearlsPlay.lastDay == today
        let balanceDone = state.game.balancePlay.lastDay == today
        let traceDone = state.game.tracePlay.lastDay == today
        let weaveDone = state.game.weavePlay.lastDay == today
        // A lost Sort is over for the day too: four misses, groups shown.
        let sortDone = state.game.sortPlay.lastDay == today
            || SortGame.isOver(state.playProgress(\.sortPlay, for: today) ?? [])
        return [
            PlayTile(route: .dailyWord, name: "Daily Word", line: dailyWordLine,
                     played: state.wordleClaimedToday,
                     fill: Theme.hex(0xFFC94D), ink: Theme.hex(0x3A2A05), glyph: .letter("A", Theme.hex(0x7A5C1E))),
            PlayTile(route: .trace, name: "Trace",
                     line: traceDone ? "Solved" : "Board \(number)",
                     played: traceDone,
                     fill: Theme.hex(0x9B7BEA), ink: Theme.hex(0x2A1A57), glyph: .trace),
            PlayTile(route: .pearls, name: "Pearls",
                     line: pearlsDone ? "Solved" : "\(PlayDeal.isSunday() ? "8×8" : "7×7") · reef \(number)",
                     played: pearlsDone,
                     fill: Theme.hex(0x4CA8E8), ink: Theme.hex(0x0B3652), glyph: .pearl),
            PlayTile(route: .balance, name: "Balance",
                     line: balanceDone ? "Solved" : "Grid \(number)",
                     played: balanceDone,
                     fill: Theme.hex(0xA5CE6B), ink: Theme.hex(0x2F4712), glyph: .dots),
            PlayTile(route: .sort, name: "Sort",
                     line: sortDone ? (state.game.sortPlay.lastDay == today ? "Solved" : "See the groups") : "Board \(number)",
                     played: sortDone,
                     fill: Theme.hex(0xF5A15C), ink: Theme.hex(0x5A2A0E), glyph: .sort),
            PlayTile(route: .weave, name: "Weave",
                     line: weaveDone ? "Solved" : "Board \(number)",
                     played: weaveDone,
                     fill: Theme.hex(0x5CC8C0), ink: Theme.hex(0x0E4744), glyph: .weave),
        ]
    }

    /// One puzzle, half the screen wide.
    private func playTile(_ tile: PlayTile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MiniBoard(glyph: tile.glyph, ink: tile.ink, size: 54)
            Spacer(minLength: 12)
            Text(tile.name)
                .font(Theme.font(17, .black))
                .tracking(-0.3)
                .foregroundStyle(tile.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(tile.line)
                .font(Theme.font(10.5, .black))
                .foregroundStyle(tile.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.top, 5)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 134, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(tile.fill)
                .overlay(alignment: .topTrailing) {
                    Circle().fill(.white.opacity(0.18)).frame(width: 70, height: 70)
                        .offset(x: 16, y: -16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
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
        let seed = abs(state.game.effectiveDay.raw.hashValue)
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
