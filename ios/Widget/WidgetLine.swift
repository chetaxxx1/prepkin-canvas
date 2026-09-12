import Foundation

/// The one line on the widget, under 40 characters, picked in this order. The
/// first rule that fits wins.
///
/// The order is by how much the fact is worth right now: a running shift beats
/// everything, then a phone that has not opened the app in days, then something
/// due in the next three hours, then the shape of the list. Nothing here counts
/// days, warns, or ends in an exclamation mark.
enum WidgetLine {
    static let maxLength = 40
    /// How far ahead a due time takes over the line.
    static let dueWindow: TimeInterval = 3 * 3600
    static let awayAfterDays = 3

    static func line(for snap: WidgetSnapshot, now: Date, calendar: Calendar = .current) -> String {
        let name = snap.name
        if let end = snap.shiftEndsAt, end > now {
            return "On shift"
        }
        if let away = calendar.dateComponents([.day], from: snap.lastOpenedAt, to: now).day,
           away >= awayAfterDays {
            return "\(name) is still here."
        }
        let tasks = today(snap, now: now, calendar: calendar)
        let open = tasks.filter { !$0.done }
        if let soon = open.filter({ $0.dueAt.map { $0 > now && $0 <= now + dueWindow } ?? false })
            .min(by: { $0.dueAt! < $1.dueAt! }) {
            let time = soon.dueAt!.formatted(.dateTime.hour().minute())
            return "\(fit(soon.title, leaving: " due \(time).".count)) due \(time)."
        }
        if tasks.isEmpty {
            return DayBank.line(name: name, on: now, seed: snap.dayBankSeed, calendar: calendar)
        }
        if open.isEmpty {
            return "All done. \(name) noticed."
        }
        let done = tasks.count - open.count
        if done > 0 {
            let lead = "\(open.count) left. "
            return lead + fit(open[0].title, leaving: lead.count + ", then done.".count) + ", then done."
        }
        let lead = open.count == 1 ? "1 thing today. " : "\(open.count) things today. "
        return lead + fit(open[0].title, leaving: lead.count + " first.".count) + " first."
    }

    /// What the small tile says: a short head in big type and a smaller line
    /// under it. The grammar of every pet widget on Mobbin — Duolingo's
    /// "845 / Last chance!", Me+'s "7 / Awesome!", Mimo's "1 / Well done!",
    /// Finch's one-word adventure state — a number or two words, then a few
    /// more, then the mascot. Same rules and order as `line`, fewer words.
    static func tile(for snap: WidgetSnapshot, now: Date, calendar: Calendar = .current) -> (head: String, sub: String) {
        let name = snap.name
        if let end = snap.shiftEndsAt, end > now {
            return ("On shift", "until \(end.formatted(.dateTime.hour().minute()))")
        }
        if let away = calendar.dateComponents([.day], from: snap.lastOpenedAt, to: now).day,
           away >= awayAfterDays {
            return (name, "is still here.")
        }
        let tasks = today(snap, now: now, calendar: calendar)
        let open = tasks.filter { !$0.done }
        if let soon = open.filter({ $0.dueAt.map { $0 > now && $0 <= now + dueWindow } ?? false })
            .min(by: { $0.dueAt! < $1.dueAt! }) {
            return (soon.dueAt!.formatted(.dateTime.hour().minute()), fit(soon.title, leaving: 20) + " due")
        }
        if tasks.isEmpty {
            return splitBank(DayBank.line(name: name, on: now, seed: snap.dayBankSeed, calendar: calendar))
        }
        if open.isEmpty {
            return ("All done", "\(name) noticed.")
        }
        let done = tasks.count - open.count
        if done > 0 {
            return ("\(open.count) left", fit(open[0].title, leaving: 20))
        }
        return ("\(open.count) to do", fit(open[0].title, leaving: 20))
    }

    /// The longest head the big type takes on one line of the small tile.
    static let headLength = 12

    /// "Nothing due. Enjoy it." → "Nothing due" / "Enjoy it." A bank line with
    /// no break, or a head too long for the big type, goes under "Nothing due".
    static func splitBank(_ line: String) -> (head: String, sub: String) {
        if let range = line.range(of: ". ") {
            let head = String(line[..<range.lowerBound])
            let sub = String(line[range.upperBound...])
            if head.count <= headLength { return (head, sub) }
        }
        return ("Nothing due", line)
    }

    /// The list as it stands now. The snapshot is only rewritten when the app
    /// runs, so on a later day the dailies are open again, open Canvas work is
    /// still open, and the rest of that day's list is unknowable and left off.
    static func today(_ snap: WidgetSnapshot, now: Date, calendar: Calendar = .current) -> [WidgetSnapshot.Task] {
        guard snap.day != Self.day(now, calendar: calendar) else { return snap.tasks }
        return snap.tasks.compactMap { t in
            if t.isDaily { var fresh = t; fresh.done = false; return fresh }
            if t.dueAt != nil, !t.done { return t }
            return nil
        }
    }

    /// The medium widget's rows: up to three, in list order. Open ones win a
    /// place when there are more than three, so a tap always has a box to land on.
    static func rows(for snap: WidgetSnapshot, now: Date, limit: Int = 3,
                     calendar: Calendar = .current) -> [WidgetSnapshot.Task] {
        let list = today(snap, now: now, calendar: calendar)
        guard list.count > limit else { return list }
        let open = list.filter { !$0.done }
        let done = list.filter(\.done)
        return Array((open + done).prefix(limit))
    }

    /// The next open task with a due time, for the lock screen's second line.
    static func nextDue(for snap: WidgetSnapshot, now: Date, calendar: Calendar = .current) -> WidgetSnapshot.Task? {
        today(snap, now: now, calendar: calendar)
            .filter { !$0.done && ($0.dueAt.map { $0 > now } ?? false) }
            .min { $0.dueAt! < $1.dueAt! }
    }

    /// "2 left today", or "All done" — the lock screen's first line.
    static func count(for snap: WidgetSnapshot, now: Date, calendar: Calendar = .current) -> String {
        let tasks = today(snap, now: now, calendar: calendar)
        let open = tasks.filter { !$0.done }.count
        if tasks.isEmpty { return "Nothing due" }
        if open == 0 { return "All done" }
        return "\(open) left today"
    }

    /// "Moss · Wed", the small widget's bottom line.
    static func stamp(_ name: String, _ date: Date) -> String {
        "\(name) · \(date.formatted(.dateTime.weekday(.abbreviated)))"
    }

    /// When the widget redraws: now, each open due time and three hours before
    /// it, noon, the check-in hour, the shift's end, and midnight. The line is
    /// picked fresh at each; nothing is fetched and nothing runs in between.
    static func timelineDates(for snapshot: WidgetSnapshot?, now: Date, calendar: Calendar = .current) -> [Date] {
        var dates: Set<Date> = [now]
        func add(_ d: Date?) { if let d, d > now { dates.insert(d) } }
        if let snapshot {
            for task in today(snapshot, now: now, calendar: calendar) where !task.done {
                add(task.dueAt.map { $0.addingTimeInterval(-dueWindow) })
                add(task.dueAt)
            }
            add(snapshot.shiftEndsAt)
            add(calendar.date(bySettingHour: snapshot.checkInHour, minute: 0, second: 0, of: now))
        }
        add(calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now))
        add(calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)))
        return dates.sorted()
    }

    /// Cuts a task name so the whole line stays under `maxLength`. At a word
    /// break when one falls in the back half of the room, so "Read for one
    /// class" becomes "Read for one…" rather than "Read for one cl…".
    static func fit(_ title: String, leaving fixed: Int) -> String {
        let room = maxLength - 1 - fixed
        let clean = title.trimmingCharacters(in: .whitespaces)
        guard clean.count > room, room > 1 else { return clean }
        var cut = String(clean.prefix(room - 1))
        if let space = cut.lastIndex(of: " "), cut.distance(from: cut.startIndex, to: space) * 2 >= room {
            cut = String(cut[..<space])
        }
        return cut.trimmingCharacters(in: .whitespaces) + "…"
    }

    static func day(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
