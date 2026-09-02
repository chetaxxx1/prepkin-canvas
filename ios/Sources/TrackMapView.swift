import SwiftUI

/// One track, as a run rather than a ladder.
///
/// The first build copied Duolingo's snaking path of bare circles. That works for
/// Duolingo because every node is the same drill; here each node is a different
/// lesson with a title, and six anonymous dots told the student nothing about what
/// they were about to open. This is a rail with the lesson beside it — you can read
/// the whole track at a glance and still see exactly where you are.
///
/// No unit headers, no XP, and **no padlocks**: an unread node is a cream circle with
/// a dot, because a padlock reads as a wall you are not good enough for. Nothing is
/// actually locked — tapping any lesson opens it.
struct TrackMapView: View {
    let trackID: String
    let onRead: (ReadingRequest) -> Void

    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var previewing: Lesson?

    private var track: Track { Catalog.track(trackID) }
    private var run: [Lesson] { Catalog.lessons(in: trackID) }
    private var doneCount: Int { run.filter { state.completedLessons.contains($0.id) }.count }

    /// The first unfinished lesson — where the slime sits and where Resume points.
    private var currentIndex: Int {
        run.firstIndex { !state.completedLessons.contains($0.id) } ?? run.count
    }

    private let railWidth: CGFloat = 54

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                LazyVStack(spacing: 0) {
                    ForEach(Array(run.enumerated()), id: \.element.id) { i, lesson in
                        row(lesson, at: i)
                    }
                    badgeRow
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
            }
            .padding(.bottom, 60)
        }
        .background(Theme.paper)
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
        .sheet(item: $previewing) { lesson in
            LessonPreviewSheet(lesson: lesson) {
                let start = state.deckProgress(lesson.id)
                previewing = nil
                // Let the sheet finish leaving before the reader takes the screen.
                Task {
                    try? await Task.sleep(for: .seconds(0.35))
                    onRead(ReadingRequest(lesson: lesson, startAt: start))
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Theme.card))
                }
                .accessibilityLabel("Back")
                Spacer()
                CoinBadge(coins: state.coins)
            }

            HStack(alignment: .center, spacing: 14) {
                TrackCover(trackID: trackID, height: 66, corner: 18)
                    .frame(width: 66)
                VStack(alignment: .leading, spacing: 6) {
                    Text(track.name)
                        .font(Theme.font(26, .black))
                        .foregroundStyle(Theme.ink)
                    HStack(spacing: 9) {
                        ProgressTrack(fraction: Double(doneCount) / Double(max(run.count, 1)),
                                      tint: TrackTint.accent(trackID))
                            .frame(width: 96)
                        Text("\(doneCount) of \(run.count) done")
                            .font(Theme.font(12.5, .heavy))
                            .foregroundStyle(Theme.muted)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 18)
    }

    // MARK: - Rows

    private func row(_ lesson: Lesson, at i: Int) -> some View {
        let done = state.completedLessons.contains(lesson.id)
        let current = i == currentIndex
        return HStack(alignment: .center, spacing: 0) {
            rail(done: done, current: current,
                 aboveDone: i <= doneCount && i > 0, belowDone: i < doneCount,
                 isFirst: i == 0, isLast: false)
            Button { open(lesson) } label: {
                current ? AnyView(currentCard(lesson)) : AnyView(plainCard(lesson, done: done))
            }
            .buttonStyle(PressStyle())
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(done ? "Done" : current ? "Next up" : "Not started")
    }

    /// The lesson you're on: bigger, with the action on it and the slime alongside.
    private func currentCard(_ lesson: Lesson) -> some View {
        let card = state.deckProgress(lesson.id)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card > 0 ? "WHERE YOU ARE" : "UP NEXT")
                        .font(Theme.font(10.5, .heavy))
                        .tracking(1.3)
                        .foregroundStyle(Theme.coralDeep)
                    Text(lesson.title)
                        .font(Theme.font(18, .black))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(card > 0
                         ? "Card \(card + 1) of \(lesson.cards.count) · \(lesson.minutes) min"
                         : "\(lesson.cards.count) cards · \(lesson.minutes) min · +\(lesson.reward)")
                        .font(Theme.font(12.5, .bold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
                SproutImage(speciesID: state.activeChibiID,
                            level: state.activeChibi.level, size: 72)
                    .offset(y: -4)
            }

            Text(card > 0 ? "Resume" : "Start")
                .font(Theme.font(15.5, .heavy))
                .foregroundStyle(Theme.onDarkWarm)
                .frame(maxWidth: .infinity).frame(height: 46)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.coral))
                .padding(.top, 12)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Theme.card)
            .shadow(color: Theme.hex(0x2E2622).opacity(0.08), radius: 14, y: 4))
        .padding(.vertical, 10)
    }

    private func plainCard(_ lesson: Lesson, done: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.title)
                    .font(Theme.font(15.5, .heavy))
                    .foregroundStyle(done ? Theme.muted : Theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(done
                     ? "Read · \(lesson.cards.count) cards"
                     : "\(lesson.cards.count) cards · \(lesson.minutes) min")
                    .font(Theme.font(12, .bold))
                    .foregroundStyle(Theme.dim)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(done ? Theme.card.opacity(0.6) : Theme.card))
        .padding(.vertical, 5)
    }

    /// The keepsake at the end of the run. An outline until it is earned.
    private var badgeRow: some View {
        let earned = doneCount == run.count && !run.isEmpty
        return HStack(alignment: .center, spacing: 0) {
            // The badge *is* the last node on the rail. Drawing a generic dot and
            // then a badge beside it read as two unrelated things.
            ZStack {
                VStack(spacing: 0) {
                    railLine(solid: earned)
                    Color.clear
                }
                ZStack {
                    Circle()
                        .fill(earned ? TrackTint.soft(trackID) : Theme.paper)
                        .overlay(Circle().strokeBorder(
                            earned ? TrackTint.accent(trackID) : Theme.hex(0xDDD2C0),
                            style: StrokeStyle(lineWidth: 2.5, dash: earned ? [] : [5, 6])))
                        .frame(width: 44, height: 44)
                    TrackIcon(trackID: trackID, size: 22)
                        .opacity(earned ? 1 : 0.35)
                }
            }
            .frame(width: railWidth)

            VStack(alignment: .leading, spacing: 2) {
                Text("Track badge")
                    .font(Theme.font(15.5, .heavy))
                    .foregroundStyle(earned ? Theme.ink : Theme.muted)
                Text(earned ? "Yours to keep" : "Finish all \(run.count) to keep it")
                    .font(Theme.font(12, .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(.leading, 14).padding(.vertical, 16)
            Spacer(minLength: 0)
        }
    }

    // MARK: - The rail

    /// The line and the node beside one row. Two flexible halves split the row's
    /// height, so the line meets its neighbours exactly whatever the card's height.
    private func rail(done: Bool, current: Bool,
                      aboveDone: Bool, belowDone: Bool,
                      isFirst: Bool, isLast: Bool) -> some View {
        ZStack {
            VStack(spacing: 0) {
                railLine(solid: aboveDone).opacity(isFirst ? 0 : 1)
                railLine(solid: belowDone).opacity(isLast ? 0 : 1)
            }
            node(done: done, current: current)
        }
        .frame(width: railWidth)
    }

    private func railLine(solid: Bool) -> some View {
        RailLine()
            .stroke(solid ? Theme.mint : Theme.hex(0xE0D4C0),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round,
                                       dash: solid ? [] : [1, 9]))
            .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func node(done: Bool, current: Bool) -> some View {
        if done {
            Circle()
                .fill(Theme.mint)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 34, height: 34)
        } else if current {
            Circle()
                .fill(Theme.coral)
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)
                .background(Circle().fill(Theme.coralSoft).frame(width: 54, height: 54))
        } else {
            Circle()
                .fill(Theme.paper)
                .overlay(Circle().strokeBorder(Theme.hex(0xE0D4C0), lineWidth: 2.5))
                .overlay { Circle().fill(Theme.hex(0xDDD2C0)).frame(width: 8, height: 8) }
                .frame(width: 30, height: 30)
        }
    }

    /// A deck you're already inside resumes; a fresh one shows what it is first.
    private func open(_ lesson: Lesson) {
        let start = state.deckProgress(lesson.id)
        if start > 0 {
            onRead(ReadingRequest(lesson: lesson, startAt: start))
        } else {
            previewing = lesson
        }
    }
}

/// A vertical line down the middle of whatever box it is given.
private struct RailLine: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        return p
    }
}
