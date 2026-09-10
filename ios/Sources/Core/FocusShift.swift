import Foundation

/// The shift clock, with no SwiftUI in it.
///
/// It used to live as five `@State` properties on `FocusView`, which meant the one
/// question the tab now has to answer well — *when does this end, and is that still
/// true after a pause?* — could only be checked by running the app. The clock moved
/// here so the notification, the Live Activity and the report can all be tested
/// against the same value the screen draws.
///
/// Two clocks, as before: `banked` is time from legs already finished, `legStart` is
/// when the current leg began. A pause freezes both the countdown and the reef; a
/// resume carries on without a jump.
struct FocusShift: Equatable {
    enum Phase: Equatable { case ready, running, paused }

    private(set) var phase: Phase = .ready
    /// The whole shift, in seconds. Zero when nothing is running.
    private(set) var total: TimeInterval = 0
    private(set) var banked: TimeInterval = 0
    private(set) var legStart: Date?

    /// A length every 90 seconds. `SwimSceneView` passes the marker on this tick.
    static let secondsPerLength: TimeInterval = 90

    /// The lengths a whole shift of this many minutes will have swum by the end.
    static func lengths(inMinutes minutes: Int) -> Int {
        Int(TimeInterval(minutes * 60) / secondsPerLength)
    }

    // MARK: - Reading

    func elapsed(at date: Date) -> TimeInterval {
        let live = legStart.map { date.timeIntervalSince($0) } ?? 0
        return min(total, banked + max(0, live))
    }

    func remaining(at date: Date) -> TimeInterval { max(0, total - elapsed(at: date)) }

    func lengths(at date: Date) -> Int { Int(elapsed(at: date) / Self.secondsPerLength) }

    /// Seconds until the marker passes again.
    func nextLengthIn(at date: Date) -> Int {
        let into = elapsed(at: date).truncatingRemainder(dividingBy: Self.secondsPerLength)
        return Int((Self.secondsPerLength - into).rounded(.up))
    }

    /// How far through, 0…1, for the bar.
    func progress(at date: Date) -> Double {
        total > 0 ? min(1, elapsed(at: date) / total) : 0
    }

    /// The whole shift in whole minutes — what finishing pays.
    var plannedMinutes: Int { Int(total / 60) }

    /// The wall-clock moment this shift runs out, or `nil` when nothing is counting
    /// down. Paused is nil on purpose: a paused shift has no end time yet, which is
    /// exactly why its notification has to come off the queue.
    func endsAt(at date: Date) -> Date? {
        guard phase == .running else { return nil }
        return date.addingTimeInterval(remaining(at: date))
    }

    // MARK: - Writing

    mutating func start(minutes: Int, at date: Date) {
        total = TimeInterval(minutes * 60)
        banked = 0
        legStart = date
        phase = .running
    }

    /// Puts back a shift that was written down before the app was killed. The phase
    /// follows the leg: a record with no leg running was paused when it was written.
    mutating func restore(minutes: Int, banked: TimeInterval, legStart: Date?) {
        total = TimeInterval(minutes * 60)
        self.banked = banked
        self.legStart = legStart
        phase = legStart == nil ? .paused : .running
    }

    mutating func pause(at date: Date) {
        guard phase == .running else { return }
        banked = elapsed(at: date)
        legStart = nil
        phase = .paused
    }

    mutating func resume(at date: Date) {
        guard phase == .paused else { return }
        legStart = date
        phase = .running
    }

    /// Back to the ready screen. Called by both endings — the timer running out and
    /// a clock-out — because neither leaves a clock behind.
    mutating func clear() {
        phase = .ready
        total = 0
        banked = 0
        legStart = nil
    }
}
