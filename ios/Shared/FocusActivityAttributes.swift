import ActivityKit
import Foundation

/// What the lock screen is told about a running shift. Shared by the app, which
/// starts and ends the activity, and the widget extension, which draws it.
///
/// Deliberately tiny. The countdown is *not* in here as a number — it is a pair of
/// dates, so the lock screen can tick with `Text(timerInterval:)` and never needs an
/// update from the app. A shift that runs 45 minutes in a pocket costs two writes:
/// one to start it and one to end it.
struct FocusShiftAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// When the current leg began, and when the shift runs out. Both move on a
        /// resume, because a resumed shift ends later than the paused one did.
        var startedAt: Date
        var endsAt: Date
        var paused: Bool
        /// The frozen clock while paused. A paused shift has no end time to count
        /// down to, so the lock screen shows this instead of a live timer.
        var remaining: TimeInterval
    }

    /// The kin's own name, as the student typed it.
    var kinName: String
    /// The still to draw, e.g. `sprout-mint-3`. The widget carries its own slim copy
    /// of these under `ActivityAssets.xcassets` — the app's catalogue is 38MB of
    /// lesson figures and reef sprites, which has no business inside an extension.
    var kinAsset: String
    /// What finishing pays. Named on the lock screen so the promise is visible from
    /// outside the app, and never re-stated as "so far" — pay is all or nothing.
    var coins: Int
    /// Lengths in the whole swim. An *attribute*, not state: a progress count on a
    /// locked phone freezes at whatever it was when the app last ran, so the lock
    /// screen states the shape of the shift and lets the app keep the running total.
    var lengths: Int
}
