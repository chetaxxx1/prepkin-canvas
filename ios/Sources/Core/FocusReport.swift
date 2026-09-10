import Foundation

/// What a shift came to, once it is over. Built by `FocusView` at the moment the
/// clock stops and handed to the report screen, so the screen never has to work out
/// what it is looking at.
struct ShiftResult: Equatable {
    /// Whole minutes that were actually on the clock.
    let minutes: Int
    /// Coins paid. The whole shift when it finished, **zero** on a clock-out — pay is
    /// all or nothing (George, 2026-09-06, commit `3bd80e1`).
    let paid: Int
    let lengths: Int
    let finished: Bool
    /// The best-shift number went up because of this shift. Said once, or not at all.
    let beatBest: Bool
    /// The task that rode along, if the student named one.
    let workingOn: DailyTask?
}

/// Every string on the shift report, in one place, so the copy can be read without
/// reading a view.
///
/// House rules it has to keep: nothing scolds, nothing is red, no streak, no "come
/// back tomorrow", and the arithmetic stays visible. "25 minutes. 25 coins." is the
/// whole honesty of the feature — a student can check it.
enum ShiftReportCopy {
    static func payLine(_ r: ShiftResult) -> String {
        guard !r.finished else {
            return "\(r.minutes) minute\(r.minutes == 1 ? "" : "s"). \(r.paid) coin\(r.paid == 1 ? "" : "s")."
        }
        guard r.minutes > 0 else {
            return "You worked less than a minute. This shift pays nothing."
        }
        return "You worked \(r.minutes) minute\(r.minutes == 1 ? "" : "s"). This shift pays nothing."
    }

    /// Under the pay line, and only when there is something to say. A clock-out gets
    /// no second line: it has been told once already.
    static func lengthsLine(_ r: ShiftResult) -> String {
        "\(r.lengths) length\(r.lengths == 1 ? "" : "s") swum"
    }

    static func bestLine(_ r: ShiftResult) -> String? {
        r.beatBest ? "That is the longest swim yet." : nil
    }

    static func title(_ r: ShiftResult) -> String {
        r.finished ? "Shift over" : "Clocked out"
    }
}

/// The one history line on the Ready screen: "3 shifts · 1h 15m".
///
/// Read off the ledger rather than a counter of its own, so it can only ever agree
/// with the coins. A clocked-out shift paid nothing, wrote no line, and so is not a
/// shift here — which keeps the number one that only ever goes up.
enum FocusWeek {
    static func line(shifts: Int, minutes: Int) -> String? {
        guard shifts > 0 else { return nil }
        return "\(shifts) shift\(shifts == 1 ? "" : "s") · \(duration(minutes))"
    }

    static func duration(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

extension Ledger {
    /// Shifts that paid this week, and the minutes they came to. Focus lines only,
    /// counted off `at` and the device calendar like `stats(inWeekOf:)` — this is a
    /// soft line on a screen, not something a promotion depends on.
    func focusWeek(of date: Date = Date(), calendar: Calendar = .current) -> (shifts: Int, minutes: Int) {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return (0, 0) }
        var shifts = 0
        var minutes = 0
        for e in entries where e.reason == .focus && week.contains(e.at) {
            shifts += 1
            minutes += e.units
        }
        return (shifts, minutes)
    }

    /// Minutes of finished shift per day, oldest first, for the last `days` days.
    ///
    /// A count of work done, never a target — there is no goal line over it and no
    /// number on it goes down, which is what keeps a graph of your own hours on the
    /// right side of "nothing that resets".
    ///
    /// Read off the ledger's `units`, the same field the weekly line uses, so the
    /// graph and the line can never disagree.
    func focusDays(
        ending: Date = Date(),
        days: Int = 7,
        calendar: Calendar = .current
    ) -> [(day: DayKey, minutes: Int)] {
        let today = calendar.startOfDay(for: ending)
        var byDay: [String: Int] = [:]
        for e in entries where e.reason == .focus {
            byDay[e.day.raw, default: 0] += e.units
        }
        return (0..<days).reversed().compactMap { back in
            guard let date = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            let key = DayKey(date, calendar: calendar)
            return (key, byDay[key.raw] ?? 0)
        }
    }
}

/// What the student says they are working on this shift.
///
/// Three states, not two: `auto` is "I have not chosen", which follows the list as
/// it changes through the day, and `nothing` is a choice the student made and which
/// the screen must not quietly overrule.
///
/// Nothing about this ever leaves the phone. `StudySync` rule 3: the wire carries a
/// kin and an end time, never a title, a course or a task.
enum WorkingOn: Equatable {
    case auto
    case nothing
    case task(String)

    /// The task the chip names, given today's list. The default is the next undone
    /// thing — the same row Home would put at the top — so tapping nothing is a
    /// valid choice (house rule 3, `design/hicks-law-plan.md`).
    func resolve(in tasks: [DailyTask]) -> DailyTask? {
        switch self {
        case .nothing: return nil
        case .auto: return tasks.first { !$0.done }
        case .task(let id): return tasks.first { $0.id == id } ?? tasks.first { !$0.done }
        }
    }
}

enum FocusCopy {
    /// The line under "Moss is on shift".
    ///
    /// It used to read "Put the phone down and let them work", which is an order, and
    /// this tab does not give orders. The fallback is for a kin whose name is long
    /// enough to push the line past 40 characters, where it would wrap or shrink.
    static func waitLine(kinName: String) -> String {
        let full = "\(kinName) is swimming. The phone can wait."
        return full.count <= 40 ? full : "The phone can wait."
    }
}
