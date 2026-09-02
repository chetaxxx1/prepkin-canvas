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
                .padding(.bottom, 124)
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
                Text("Learn")
                    .font(Theme.font(34, .black))
                    .foregroundStyle(Theme.ink)
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

    private var monthLine: String {
        let n = state.lessonsThisMonth
        switch n {
        case 0: return "Two minutes is enough to start"
        case 1: return "1 lesson this month"
        default: return "\(n) lessons this month"
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

    private var savedRow: some View {
        NavigationLink(value: LearnRoute.saved) {
            HStack(spacing: 13) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.coral)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.coralSoft))
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
