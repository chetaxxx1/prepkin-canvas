import Foundation

/// One calendar day in the user's own time zone, written as "2026-08-29".
///
/// Every day-scoped rule in the app — task rollover, once-a-day rewards — keys off
/// this string and never off `Date` math. Comparing dates is what lets a midnight
/// rollover, a flight across time zones, or a hand-set clock either wipe a day or
/// pay for it twice. Comparing day keys can't.
struct DayKey: Hashable, Comparable, CustomStringConvertible {
    let raw: String

    init(raw: String) { self.raw = raw }

    init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        raw = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func today(_ calendar: Calendar = .current) -> DayKey {
        DayKey(Date(), calendar: calendar)
    }

    /// The later of two days. Used by the clock-rollback guard.
    static func latest(_ a: DayKey, _ b: DayKey) -> DayKey { a < b ? b : a }

    static func < (a: DayKey, b: DayKey) -> Bool { a.raw < b.raw }
    var description: String { raw }
}

/// Encoded as a bare string, so the save file stays readable when something goes wrong.
extension DayKey: Codable {
    init(from decoder: Decoder) throws {
        raw = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(raw)
    }
}

/// One calendar week, written as "2026-W36".
///
/// Built from a `DayKey`, never from a `Date`, so it inherits the same clock-rollback
/// guard: a week can only turn over when `effectiveDay` says it has, and winding the
/// device date backwards can't re-open a week that already settled.
///
/// The calendar is pinned to ISO 8601 rather than `.current`. Weeks start on Monday
/// in one place and on Sunday in another, and a student who changes their phone's
/// region should not find their week has moved under them.
struct WeekKey: Hashable, Comparable, CustomStringConvertible, Codable {
    let raw: String

    init(raw: String) { self.raw = raw }

    init(_ day: DayKey, calendar: Calendar = WeekKey.calendar) {
        let parts = day.raw.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
              let year = calendar.dateComponents([.yearForWeekOfYear], from: date).yearForWeekOfYear,
              let week = calendar.dateComponents([.weekOfYear], from: date).weekOfYear
        else { raw = ""; return }
        raw = String(format: "%04d-W%02d", year, week)
    }

    /// ISO 8601: Monday first, week 1 is the one holding the first Thursday. The time
    /// zone stays the student's own — the week turns over at their midnight, not UTC's.
    static var calendar: Calendar = {
        var c = Calendar(identifier: .iso8601)
        c.timeZone = .current
        return c
    }()

    /// "2026-W07" sorts before "2026-W37", and "2025-W52" before "2026-W01", because
    /// the week is always two digits. A plain string compare is the whole test.
    static func < (a: WeekKey, b: WeekKey) -> Bool { a.raw < b.raw }
    var description: String { raw }

    init(from decoder: Decoder) throws {
        raw = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(raw)
    }
}
