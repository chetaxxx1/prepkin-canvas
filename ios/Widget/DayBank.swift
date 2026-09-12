import Foundation

/// The line the widget says on a day with nothing on the list.
///
/// Thirty to start, from the 2026-09-09 plan. No exclamation marks, nothing about
/// missing anything, nothing that counts days. The kin's own name goes where
/// "Moss" is. Seeded by the date, so the line changes every morning and stays the
/// same all day; the seed is offset per phone so two friends do not read the same
/// one.
enum DayBank {
    static let lines: [String] = [
        "Moss is just here.",
        "Nothing due. Enjoy it.",
        "Quiet tank today.",
        "Moss found a warm spot.",
        "Free day. Moss approves.",
        "Moss is watching the bubbles.",
        "Nothing on the list. Rare.",
        "Moss is napping. Same.",
        "Coins only go up. So does Moss.",
        "A quiet week keeps you where you are.",
        "Moss did a lap for no reason.",
        "Nothing due. Go outside.",
        "Moss is guarding the reef.",
        "Slow morning in the tank.",
        "Moss says hi. That's all.",
        "The tank is clean. Moss is smug.",
        "Nothing due. Moss is unbothered.",
        "Moss is practicing a wave.",
        "Sun's on the reef today.",
        "Moss counted the pebbles. Nine.",
        "No list. Moss is fine with that.",
        "Moss found the good current.",
        "Nothing due. Read something.",
        "Moss is hiding in the kelp.",
        "Calm water today.",
        "Moss is doing nothing on purpose.",
        "Free day. The tank agrees.",
        "Moss is watching you scroll.",
        "Nothing due. Text a friend.",
        "Moss is here whenever.",
    ]

    /// The day's line. The same `date` anywhere in one day gives the same answer,
    /// and the next day always gives a different one.
    ///
    /// A long kin name (they run to 14 letters) can push a line past the widget's
    /// 40 characters; that day takes the next line that fits instead.
    static func line(name: String, on date: Date, seed: Int, calendar: Calendar = .current) -> String {
        let start = ((dayNumber(date, calendar: calendar) + seed) % lines.count + lines.count) % lines.count
        for step in 0..<lines.count {
            let line = lines[(start + step) % lines.count].replacingOccurrences(of: "Moss", with: name)
            if line.count < WidgetLine.maxLength { return line }
        }
        return "Nothing due."
    }

    /// A count of days from the calendar's own year, month and day, so it cannot
    /// slip by one across a clock change the way `ordinality(of: .day)` can.
    static func dayNumber(_ date: Date, calendar: Calendar) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 2000, m = c.month ?? 1, d = c.day ?? 1
        let a = (14 - m) / 12
        let yy = y + 4800 - a
        let mm = m + 12 * a - 3
        return d + (153 * mm + 2) / 5 + 365 * yy + yy / 4 - yy / 100 + yy / 400 - 32045
    }
}
