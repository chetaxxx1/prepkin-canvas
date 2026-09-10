import ActivityKit
import Foundation

/// Puts the running shift on the lock screen and in the Dynamic Island.
///
/// Silent on every failure. Live Activities can be switched off per app in Settings,
/// and a student who has switched them off still gets the shift, the coins and the
/// end-of-shift notification — so nothing here is ever worth an error on screen.
///
/// The countdown is not pushed. `FocusShiftAttributes` carries a pair of dates and
/// the lock screen ticks itself, so the only writes are start, one per length, pause,
/// resume and end.
@MainActor
enum FocusLiveActivity {
    private static var current: Activity<FocusShiftAttributes>?

    static func start(kinName: String, kinAsset: String, shift: FocusShift, now: Date = Date()) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled,
              let content = content(for: shift, at: now) else { return }
        // An activity outlives the process that started it. If the app was killed
        // mid-shift, the lock screen still has one and `current` does not — so it is
        // adopted and ended here rather than left counting down to nothing.
        endStrays()
        let attributes = FocusShiftAttributes(
            kinName: kinName, kinAsset: kinAsset,
            coins: shift.plannedMinutes,
            lengths: FocusShift.lengths(inMinutes: shift.plannedMinutes))
        current = try? Activity.request(attributes: attributes, content: content)
    }

    /// Ends every shift activity this app owns. Called before starting one, and on
    /// launch, so a killed app cannot leave a fish swimming on somebody's lock screen.
    static func endStrays() {
        current = nil
        for activity in Activity<FocusShiftAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// Pause and resume. Nothing else needs a write: the countdown ticks itself and
    /// the length total is fixed for the whole shift, so a 45 in a pocket costs two
    /// writes end to end.
    static func update(shift: FocusShift, now: Date = Date()) {
        guard let activity = current, let content = content(for: shift, at: now) else { return }
        Task { await activity.update(content) }
    }

    static func end() {
        guard let activity = current else { return }
        current = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    private static func content(for shift: FocusShift,
                                at now: Date) -> ActivityContent<FocusShiftAttributes.ContentState>? {
        let remaining = shift.remaining(at: now)
        guard shift.phase != .ready, remaining > 0 else { return nil }
        let state = FocusShiftAttributes.ContentState(
            startedAt: now,
            endsAt: now.addingTimeInterval(remaining),
            paused: shift.phase == .paused,
            remaining: remaining)
        // Stale a minute after the shift should have ended. If the app was killed
        // mid-shift and never got to end the activity, the lock screen dims itself
        // rather than sitting at 0:00 forever.
        return ActivityContent(state: state,
                               staleDate: now.addingTimeInterval(remaining + 60))
    }
}
