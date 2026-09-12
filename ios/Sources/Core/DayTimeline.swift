import Foundation

/// How one day lays out on a clock — the rules behind `DayTimelineView`, as
/// pure functions so they can be tested without a screen.
///
/// The axis is a true clock at 48pt per hour, but it is not a 24-hour scroll:
/// the day is a list of *segments* in time order, and the free time between
/// two things is one row rather than a run of empty hours. A gap under two
/// hours is a short row that only says its length ("30m"); a gap of two hours
/// or more is a full row that names the wait ("3h 50m free until 2:00") and
/// offers a place to put something. The day ends with what is left of it.
///
/// On today, `now` is a segment of its own, placed at its time. Everything
/// before it is over, so a gap that ends at `now` is not drawn — there is
/// nothing to add to the past — and a gap that starts at `now` says how long
/// until the next thing. When `now` falls inside a class, the class carries
/// the line at the right height instead (Saturn lights the class you are in).
enum DayTimeline {

    /// Something with a place on the clock, in minutes past midnight. A due
    /// time is a point (`end == start`); a class runs from `start` to `end`.
    struct Span: Equatable {
        let start: Int
        let end: Int

        init(start: Int, end: Int? = nil) {
            self.start = start
            self.end = max(start, end ?? start)
        }

        var minutes: Int { end - start }
    }

    enum Segment: Equatable {
        /// The item at this index in the spans handed in. `nowAt` is where
        /// the now-line crosses it, 0...1 of its height, when now is inside it.
        case item(Int, nowAt: Double? = nil)
        /// Free time, from one minute to another.
        case gap(from: Int, to: Int)
        /// The now-line, between two things.
        case now
        /// What is left of the day after the last thing. `from` is nil for a
        /// day with nothing timed on it at all.
        case rest(from: Int?)
    }

    /// A free run this long or longer gets the full row with the invitation.
    static let longGap = 120

    /// `spans` in any order; `now` in minutes past midnight, or nil for a day
    /// that is not today.
    static func segments(_ spans: [Span], now: Int?) -> [Segment] {
        let order = spans.indices.sorted { (spans[$0].start, spans[$0].end) < (spans[$1].start, spans[$1].end) }
        var out: [Segment] = []
        /// The end of the last thing placed. Nil until something is.
        var cursor: Int?
        var nowPlaced = now == nil

        func placeNow(before next: Int?) {
            guard let now, !nowPlaced else { return }
            nowPlaced = true
            out.append(.now)
            if let next, next > now { out.append(.gap(from: now, to: next)) }
        }

        for i in order {
            let span = spans[i]
            if let now, !nowPlaced {
                if now < span.start {
                    placeNow(before: span.start)
                } else if now < span.end {
                    // Inside this one. The line rides on the block itself.
                    nowPlaced = true
                    out.append(.item(i, nowAt: Double(now - span.start) / Double(span.minutes)))
                    cursor = max(cursor ?? 0, span.end)
                    continue
                }
                // Still in the past: no gap rows, nothing to add there.
            } else if let c = cursor, span.start > c {
                out.append(.gap(from: c, to: span.start))
            }
            out.append(.item(i))
            cursor = max(cursor ?? 0, span.end)
        }
        if !nowPlaced { placeNow(before: nil) }
        if let now, now >= (cursor ?? 0) {
            out.append(.rest(from: now))
        } else {
            out.append(.rest(from: cursor))
        }
        return out
    }

    // MARK: - Words for the axis

    /// "30m" · "1h" · "1h 30m" · "3h 50m".
    static func length(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    /// "9 AM" on the hour, "3:30" off it — the label an axis row carries.
    static func hourLabel(_ minute: Int, calendar: Calendar = .current) -> String {
        let date = calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: Date()) ?? Date()
        if minute % 60 == 0 {
            return date.formatted(Date.FormatStyle(locale: calendar.locale ?? .current).hour())
        }
        return clock(minute, calendar: calendar)
    }

    /// "2:00" — the time without its AM/PM, for "free until 2:00" and an
    /// off-hour axis label. Built from the locale's own pattern with the
    /// meridiem struck out, so a 24-hour locale still reads `14:00`.
    static func clock(_ minute: Int, calendar: Calendar = .current) -> String {
        let date = calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: Date()) ?? Date()
        return formatter(for: calendar.locale ?? .current).string(from: date)
    }

    static func clock(_ date: Date) -> String { formatter(for: .current).string(from: date) }

    private static var formatters: [String: DateFormatter] = [:]

    private static func formatter(for locale: Locale) -> DateFormatter {
        if let f = formatters[locale.identifier] { return f }
        let f = DateFormatter()
        f.locale = locale
        let pattern = DateFormatter.dateFormat(fromTemplate: "jmm", options: 0, locale: locale) ?? "h:mm"
        f.dateFormat = pattern.replacingOccurrences(of: "a", with: "").trimmingCharacters(in: .whitespaces)
        formatters[locale.identifier] = f
        return f
    }

    /// Minutes past midnight, in the given calendar.
    static func minute(of date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
