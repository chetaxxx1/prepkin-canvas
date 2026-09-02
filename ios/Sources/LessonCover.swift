import SwiftUI

/// The art that stands for a lesson everywhere it is offered.
///
/// One component, used by the Continue hero, the two pick cards, the track map and
/// the preview sheet — so a lesson looks like itself wherever you meet it. Before
/// this, every card on Learn was a white rectangle with a 26pt mark in the corner,
/// and the screen read as a settings list rather than something worth opening.
///
/// A lesson with a figure shows the figure at its last reveal: the cover *is* the
/// lesson. Everything else shows its track mark, large, on the track's tint.
struct LessonCover: View {
    let lesson: Lesson
    var height: CGFloat = 132
    var corner: CGFloat = 18
    /// Off below roughly 80pt, where a whole figure is just texture.
    var showsFigure = true

    private var usesFigure: Bool { showsFigure && LessonFigure.exists(lesson.figure) }

    var body: some View {
        ZStack {
            if usesFigure {
                // The figure paints its own field to the edges, so the cover is tinted
                // whatever its shape.
                LessonFigure(id: lesson.figure, step: 9)
            } else {
                TrackTint.soft(lesson.trackID)
                TrackIcon(trackID: lesson.trackID, size: min(height * 0.5, 64))
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

/// The square version, for rows where the cover is a thumbnail beside the title.
struct LessonThumb: View {
    let lesson: Lesson
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            LessonFigure.field(lesson.figure)
            TrackIcon(trackID: lesson.trackID, size: size * 0.56)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

/// A track's own cover, for the shelf on Learn.
struct TrackCover: View {
    let trackID: String
    var height: CGFloat = 92
    var corner: CGFloat = 16

    var body: some View {
        ZStack {
            TrackTint.soft(trackID)
            TrackIcon(trackID: trackID, size: height * 0.48)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}
