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
