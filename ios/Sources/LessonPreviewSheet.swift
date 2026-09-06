import SwiftUI

/// "How big is this?", answered before you commit.
///
/// The real figure as cover art, the track, three lines of plain what-you'll-learn,
/// and the size of the commitment in one line. One Start button, with nothing
/// competing with it.
struct LessonPreviewSheet: View {
    let lesson: Lesson
    let onStart: () -> Void

    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    cover

                    Text(Catalog.track(lesson.trackID).name)
                        .font(Theme.font(12, .heavy))
                        .foregroundStyle(TrackTint.ink(lesson.trackID))
                        .padding(.horizontal, 11).padding(.vertical, 5)
                        .background(Capsule().fill(TrackTint.soft(lesson.trackID)))
                        .padding(.top, 20)

                    Text(lesson.title)
                        .font(Theme.font(27, .black))
                        .lineSpacing(27 * 0.14)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)

                    Text("What you'll learn")
                        .font(Theme.font(13.5, .heavy))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 22)

                    Text(lesson.blurb)
                        .font(Theme.font(15, .bold))
                        .lineSpacing(15 * 0.5)
                        .foregroundStyle(Theme.hex(0x7C6F68))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)

                    HStack(spacing: 7) {
                        Text("\(lesson.minutes) min · \(lesson.cards.count) cards ·")
                        CoinDisc(size: 15)
                        Text("+\(lesson.reward) coins")
                    }
                    .font(Theme.font(13.5, .heavy))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 26)
                .padding(.bottom, 120)
            }
            .scrollBounceBehavior(.basedOnSize)

            Button(action: onStart) {
                Text(state.deckProgress(lesson.id) > 0 ? "Resume" : "Start")
                    .font(Theme.font(18, .heavy))
                    .foregroundStyle(Theme.onDarkWarm)
                    .frame(maxWidth: .infinity).frame(height: 58)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
            .padding(.horizontal, 24).padding(.bottom, 30)
            .background(
                LinearGradient(colors: [Theme.card.opacity(0), Theme.card, Theme.card],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 150)
                    .allowsHitTesting(false),
                alignment: .bottom)
        }
        .background(Theme.card)
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.paper))
                    .padding(4)
                    .contentShape(Rectangle())
                    .padding(-4)
            }
            .accessibilityLabel("Close")
            .padding(.trailing, 20).padding(.top, 20)
        }
        .presentationDetents([.fraction(0.86)])
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
    }

    /// The same art the lesson wears everywhere else it is offered.
    private var cover: some View {
        LessonCover(lesson: lesson, height: 178, corner: 20)
    }
}
