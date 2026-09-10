import Foundation

/// A date typed in words inside a task title: "Bio quiz fri 4pm".
///
/// Todoist's quick add, mechanic for mechanic. The phrase is found while the
/// student types, lit up inside the field, and repeated as a chip under it. The
/// title is whatever is left once the phrase is taken out, so one line of typing
/// is a complete task.
///
/// What it reads: `today`, `tomorrow`, `mon`…`sun` (and the long spellings),
/// `next week`, `9/14`, `sep 14`, and a time on the end of any of those —
/// `fri 4pm`, `sep 14 9:30am`, `16:00`. A bare number is never a time: "Ch. 5"
/// stays part of the title. A leading `by`, `on`, `due` or `at` is eaten with the
/// phrase, the way Todoist eats "by fri 4 pm".
struct DatePhrase: Equatable {
    var day: DayKey
    /// Minutes past midnight, or nil when only a day was typed.
    var minute: Int?
    /// The characters it was read from, so the field can light exactly those.
    var range: Range<String.Index>
    /// What the chip under the field says: "Friday 4:00 PM".
    var label: String
}

extension DatePhrase {

    // MARK: - Reading

    /// The first date phrase in the text, or nil.
    static func parse(_ text: String, now: Date = Date(), calendar: Calendar = .current) -> DatePhrase? {
        if let m = Self.dayThenTime.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let whole = Range(m.range, in: text),
           let phrase = Range(m.range(at: 1), in: text),
           let day = day(from: String(text[phrase]), now: now, calendar: calendar) {
            let minute = self.minute(m, in: text, twelve: (2, 3, 4), twentyFour: (5, 6))
            return DatePhrase(day: day, minute: minute, range: whole,
                              label: label(day: day, minute: minute, now: now, calendar: calendar))
        }
        // No day, but a time on its own means today: "essay draft 4pm".
        if let m = Self.timeOnly.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let whole = Range(m.range, in: text),
           let minute = self.minute(m, in: text, twelve: (1, 2, 3), twentyFour: (4, 5)) {
            let day = DayKey(now, calendar: calendar)
            return DatePhrase(day: day, minute: minute, range: whole,
                              label: label(day: day, minute: minute, now: now, calendar: calendar))
        }
        return nil
    }

    /// The title with the phrase taken out and the spacing tidied.
    static func title(_ text: String, without phrase: DatePhrase?) -> String {
        var out = text
        if let phrase { out.removeSubrange(phrase.range) }
        return out.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Saying it back

    /// "Today" · "Tomorrow" · "Friday" · "Sep 14", plus the time when there is one.
    static func label(day: DayKey, minute: Int?, now: Date = Date(),
                      calendar: Calendar = .current) -> String {
        let today = DayKey(now, calendar: calendar)
        var out: String
        if day == today {
            out = "Today"
        } else if day == today.adding(days: 1, calendar: calendar) {
            out = "Tomorrow"
        } else if let date = day.date(calendar: calendar),
                  day > today, day < today.adding(days: 7, calendar: calendar) {
            out = date.formatted(.dateTime.weekday(.wide))
        } else if let date = day.date(calendar: calendar) {
            out = date.formatted(.dateTime.month(.abbreviated).day())
        } else {
            out = day.raw
        }
        if let minute, let date = day.date(calendar: calendar),
           let at = calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: date) {
            out += " " + at.formatted(.dateTime.hour().minute())
        }
        return out
    }

    // MARK: - The two patterns

    private static let lead = "(?:(?:by|on|due(?:\\s+on)?|at)\\s+)?"
    private static let dayWord = """
    (next\\s+week\
    |today\
    |tomorrow\
    |(?:mon|tues?|wed(?:nes)?|thur?s?|fri|sat(?:ur)?|sun)(?:day)?\
    |(?:jan|feb|mar|apr|may|jun|jul|aug|sept?|oct|nov|dec)[a-z]*\\.?\\s+\\d{1,2}(?:st|nd|rd|th)?\
    |\\d{1,2}/\\d{1,2})
    """
    /// A bare number is never a time. It needs an am/pm or a colon, or "Ch. 5"
    /// becomes five o'clock.
    private static let clock = "(\\d{1,2})(?::(\\d{2}))?\\s*(am|pm)|(\\d{1,2}):(\\d{2})"

    /// Plain word boundaries rather than look-around, so "Ch. 5" and "Mondays"
    /// cannot be read as a date and the pattern stays free of punctuation the
    /// copy sweep reads as shouting.
    private static let edge = "\\b"

    private static let dayThenTime = regex(
        "\(edge)\(lead)\(dayWord)(?:\\s+(?:at\\s+)?(?:\(clock)))?\(edge)")

    private static let timeOnly = regex("\(edge)\(lead)(?:\(clock))\(edge)")

    private static func regex(_ pattern: String) -> NSRegularExpression {
        // The patterns are fixed text, so a throw here is a programming mistake.
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    // MARK: - Working out which day

    private static func day(from phrase: String, now: Date, calendar: Calendar) -> DayKey? {
        let s = phrase.lowercased().trimmingCharacters(in: .whitespaces)
        let today = DayKey(now, calendar: calendar)

        if s == "today" { return today }
        if s == "tomorrow" { return today.adding(days: 1, calendar: calendar) }
        if s.hasPrefix("next") {
            return next(weekday: 2, after: now, calendar: calendar, skippingToday: true)
        }
        if let weekday = weekdayNumber(s) {
            return next(weekday: weekday, after: now, calendar: calendar, skippingToday: false)
        }
        if let slash = numericDay(s, now: now, calendar: calendar) { return slash }
        return namedMonthDay(s, now: now, calendar: calendar)
    }

    /// Sunday is 1, the way `Calendar` counts. "next week" resolves to Monday.
    private static func weekdayNumber(_ s: String) -> Int? {
        let names = ["sun": 1, "mon": 2, "tue": 3, "wed": 4, "thu": 5, "fri": 6, "sat": 7]
        return names[String(s.prefix(3))]
    }

    /// The coming one, today included — typing "friday" on a Friday means today,
    /// the way it does in Todoist. "next week" asks for Monday and skips today,
    /// so typing it on a Monday moves a whole week rather than nowhere.
    private static func next(weekday: Int, after now: Date, calendar: Calendar,
                             skippingToday: Bool) -> DayKey {
        let start = DayKey(now, calendar: calendar)
        for step in (skippingToday ? 1 : 0)...7 {
            let candidate = start.adding(days: step, calendar: calendar)
            guard let date = candidate.date(calendar: calendar) else { continue }
            if calendar.component(.weekday, from: date) == weekday { return candidate }
        }
        return start
    }

    /// "9/14" — month first, the way a US student writes it. A date that has gone
    /// past rolls into next year.
    private static func numericDay(_ s: String, now: Date, calendar: Calendar) -> DayKey? {
        let parts = s.split(separator: "/").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return build(month: parts[0], day: parts[1], now: now, calendar: calendar)
    }

    /// "sep 14", "sept. 14", "september 14th".
    private static func namedMonthDay(_ s: String, now: Date, calendar: Calendar) -> DayKey? {
        let months = ["jan", "feb", "mar", "apr", "may", "jun",
                      "jul", "aug", "sep", "oct", "nov", "dec"]
        let pieces = s.split(whereSeparator: { $0 == " " || $0 == "." })
        guard let head = pieces.first, let tail = pieces.last,
              let month = months.firstIndex(of: String(head.prefix(3))),
              let day = Int(tail.prefix(while: \.isNumber)) else { return nil }
        return build(month: month + 1, day: day, now: now, calendar: calendar)
    }

    private static func build(month: Int, day: Int, now: Date, calendar: Calendar) -> DayKey? {
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }
        let year = calendar.component(.year, from: now)
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)),
              calendar.component(.day, from: date) == day else { return nil }
        let key = DayKey(date, calendar: calendar)
        guard key < DayKey(now, calendar: calendar) else { return key }
        guard let rolled = calendar.date(from: DateComponents(year: year + 1, month: month, day: day))
        else { return key }
        return DayKey(rolled, calendar: calendar)
    }

    // MARK: - Working out the time

    private static func minute(_ m: NSTextCheckingResult, in text: String,
                               twelve: (Int, Int, Int), twentyFour: (Int, Int)) -> Int? {
        if let hour = int(m, twelve.0, in: text), let half = string(m, twelve.2, in: text) {
            guard (1...12).contains(hour) else { return nil }
            let mins = int(m, twelve.1, in: text) ?? 0
            guard (0..<60).contains(mins) else { return nil }
            let pm = half.lowercased() == "pm"
            let h = pm ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour)
            return h * 60 + mins
        }
        if let hour = int(m, twentyFour.0, in: text), let mins = int(m, twentyFour.1, in: text) {
            guard (0..<24).contains(hour), (0..<60).contains(mins) else { return nil }
            return hour * 60 + mins
        }
        return nil
    }

    private static func string(_ m: NSTextCheckingResult, _ i: Int, in text: String) -> String? {
        guard i < m.numberOfRanges, let r = Range(m.range(at: i), in: text) else { return nil }
        return String(text[r])
    }

    private static func int(_ m: NSTextCheckingResult, _ i: Int, in text: String) -> Int? {
        string(m, i, in: text).flatMap(Int.init)
    }
}
