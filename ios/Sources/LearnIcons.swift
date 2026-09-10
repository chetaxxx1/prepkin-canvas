import SwiftUI

/// The object on a track's card, from the same illustrated set as the task rows.
///
/// This used to be a second icon language — a flat black glyph on a pastel square —
/// and it is most of why Learn did not look like the rest of the app. A track tile
/// and a task row now draw from one set.
struct TrackIcon: View {
    let trackID: String
    var size: CGFloat = 30

    /// The study *track* and the study *task category* are different objects: a
    /// stack of books against a stack of flashcards. Only this id needs a detour.
    static func asset(_ trackID: String) -> String {
        switch trackID {
        case "finance", "philosophy", "psychology", "people", "work": return trackID
        default: return "studyTrack"
        }
    }

    var body: some View {
        Image("icon-" + Self.asset(trackID))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

// MARK: - Track surfaces

/// Per-track surface colours.
///
/// Cover panels and tiles are art surfaces, so they take the same licensed exception
/// to the low-chroma rule that figures do. Without them every card on Learn was a
/// white rectangle with a small mark on it, and the screen read as a settings list.
enum TrackTint {
    /// The panel a cover sits on. The same six tints the icon tiles use, looked up
    /// through the icon rather than repeated here — one table, so a track's card and
    /// its row can never drift apart.
    static func soft(_ id: String) -> Color { IconTint.of(TrackIcon.asset(id)).soft }

    /// The saturated member of the family, for progress and small marks.
    static func accent(_ id: String) -> Color {
        switch id {
        case "finance": return Theme.coin
        case "study": return Theme.mint
        case "psychology": return Theme.hex(0x9BC8F2)
        case "people": return Theme.coral
        case "work": return Theme.leaf
        default: return Theme.hex(0xC3B2F0)
        }
    }

    /// Text that has to read on `soft`.
    static func ink(_ id: String) -> Color {
        switch id {
        case "finance": return Theme.coinDark
        case "study": return Theme.mintDark
        case "psychology": return Theme.hex(0x3D6FA8)
        case "people": return Theme.coralDeep
        case "work": return Theme.hex(0x5A7A2E)
        default: return Theme.hex(0x6B5CA5)
        }
    }
}
