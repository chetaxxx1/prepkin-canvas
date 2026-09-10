import Foundation

/// Everything that can make a student Plus right now, in one value.
///
/// `PlusGate` says what a gate is worth for a given `isPlus`. This says what
/// `isPlus` *is*, and it is the only place in the app that decides. Three ways in:
/// a paid subscription, the gift week, and the simulator's `-unlockAll`. A view
/// never adds a fourth by writing `plus.entitlement.isActive` of its own.
struct PlusAccess: Equatable {

    /// A live App Store subscription, including a card that bounced and is inside
    /// Apple's billing grace period. A bounced card must not cost a student a perk.
    var paid = false
    /// When the gift week runs out. `nil` before the gift, in the past after it.
    var giftEndsAt: Date?
    /// `-unlockAll` on the simulator. Never true in a shipped build.
    var debug = false

    static let none = PlusAccess()

    func isOn(at now: Date = Date()) -> Bool {
        if paid || debug { return true }
        return giftEndsAt.map { $0 > now } ?? false
    }

    /// Plus, but as a gift rather than a purchase. The sheet reads this to keep a
    /// price off a screen the student has not been asked to pay for.
    func isGift(at now: Date = Date()) -> Bool {
        !paid && !debug && (giftEndsAt.map { $0 > now } ?? false)
    }

    func value(_ gate: PlusGate, installedAt: Date? = nil, at now: Date = Date()) -> Int {
        PlusGate.value(gate, isPlus: isOn(at: now), installedAt: installedAt)
    }

    func isOn(_ gate: PlusGate, installedAt: Date? = nil, at now: Date = Date()) -> Bool {
        PlusGate.isOn(gate, isPlus: isOn(at: now), installedAt: installedAt)
    }
}

// MARK: - The gift week

/// Plus, free, for seven days, after three finished Canvas tasks.
///
/// The rules here are mostly things *not* to do, and they are in `PLUS-SPEC.md`
/// section 6: it is never announced before it arrives, there is no reminder at day
/// five, there is no number on screen that counts down, and the words "your trial
/// is ending" appear nowhere. The sheet arrives once, on the day it stops, and
/// after that Plus is only ever reached by a student tapping something on purpose.
enum PlusGift {

    /// Finished Canvas tasks before the week turns on.
    static let earnedAfter = 3
    static let days = 7

    /// Whether this count has earned the gift. Called after a task posts.
    static func earned(canvasFinished: Int) -> Bool { canvasFinished >= earnedAfter }

    static func endDate(from start: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: start) ?? start
    }

    /// The three lines on the timeline screen, in order.
    ///
    /// Headspace's and Quizlet's shape: a plain dated list, one line each. The last
    /// line says nothing is charged, because nothing is — no card was ever taken.
    static func timeline(start: Date, calendar: Calendar = .current) -> [Row] {
        let end = endDate(from: start, calendar: calendar)
        let note = calendar.date(byAdding: .day, value: days - 2, to: start) ?? start
        return [
            Row(when: "Today", what: "Plus is on. Nothing to cancel, because nothing was started."),
            Row(when: Self.stamp(note, calendar: calendar), what: "A note, so the last two days are not a surprise."),
            Row(when: Self.stamp(end, calendar: calendar), what: "It ends. Nothing is charged. Everything you made stays."),
        ]
    }

    struct Row: Equatable {
        var when: String
        var what: String
    }

    /// "Sep 17". A date, never "in 5 days" — a number that goes down is the one
    /// thing section 6 forbids on this screen.
    static func stamp(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return f.string(from: date)
    }
}
